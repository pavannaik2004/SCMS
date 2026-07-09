const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

/**
 * Enriches complaint record(s) with human-readable category, department and
 * assignee names plus a flat `photoUrls` array, so the Flutter client can
 * render them directly. The Complaint model has no Prisma relation to
 * Category/Department, so the names are resolved via lightweight in-memory maps.
 *
 * Mutates the records in place and returns the original input (object or array).
 */
async function enrichComplaints(input) {
  if (!input) return input;
  const list = Array.isArray(input) ? input : [input];
  if (list.length === 0) return input;

  const assignedIds = [...new Set(list.map((c) => c.assignedToId).filter(Boolean))];

  const [categories, departments, assignees] = await Promise.all([
    prisma.category.findMany({ select: { id: true, name: true } }),
    prisma.department.findMany({ select: { id: true, name: true } }),
    assignedIds.length
      ? prisma.user.findMany({
          where: { id: { in: assignedIds } },
          select: { id: true, name: true },
        })
      : Promise.resolve([]),
  ]);

  const catMap = Object.fromEntries(categories.map((c) => [c.id, c.name]));
  const deptMap = Object.fromEntries(departments.map((d) => [d.id, d.name]));
  const userMap = Object.fromEntries(assignees.map((u) => [u.id, u.name]));

  for (const c of list) {
    c.categoryName = catMap[c.categoryId] || null;
    c.departmentName = deptMap[c.departmentId] || null;
    c.submittedByName = c.submittedBy ? c.submittedBy.name : null;
    c.assignedToName = c.assignedToId ? userMap[c.assignedToId] || null : null;
    const media = Array.isArray(c.mediaItems) ? c.mediaItems : [];
    // Original submission photos (exclude staff resolution proof).
    c.photoUrls = media.filter((m) => (m.purpose || 'ORIGINAL') !== 'PROOF').map((m) => m.url);
    // Staff-uploaded resolution proof, surfaced separately for the admin review UI.
    c.proofUrls = media.filter((m) => m.purpose === 'PROOF').map((m) => m.url);
  }

  return input;
}

module.exports = { enrichComplaints };
