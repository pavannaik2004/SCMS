const express = require('express');
const { PrismaClient } = require('@prisma/client');
const { sendSuccess } = require('../utils/responseHelper');
const authenticate = require('../middleware/authenticate');
const { enrichComplaints } = require('../utils/enrichComplaints');

const router = express.Router();
const prisma = new PrismaClient();

// Aggregated analytics are read-only, system-wide numbers. Any authenticated
// user may view them (the dashboards expose a shared "Stats" tab to every role).
// Write actions remain guarded on their own routes.
router.use(authenticate);

/**
 * GET /api/analytics/summary
 * Generates aggregated metrics and distributions for visual dashboard charts
 */
router.get('/summary', async (req, res, next) => {
  try {
    const totalComplaints = await prisma.complaint.count();
    
    const activeComplaints = await prisma.complaint.count({
      where: {
        status: {
          notIn: ['RESOLVED', 'CLOSED', 'REJECTED']
        }
      }
    });

    const resolvedComplaints = await prisma.complaint.count({
      where: {
        status: {
          in: ['RESOLVED', 'CLOSED']
        }
      }
    });

    const slaBreachedCount = await prisma.complaint.count({
      where: { isSlaBreached: true }
    });

    // Compute average resolution timeframe in hours (createdAt -> resolved/closed updatedAt)
    const resolvedItems = await prisma.complaint.findMany({
      where: {
        status: { in: ['RESOLVED', 'CLOSED'] }
      },
      select: {
        createdAt: true,
        updatedAt: true
      }
    });

    let averageResolutionTimeHours = 0.0;
    if (resolvedItems.length > 0) {
      const totalMs = resolvedItems.reduce((acc, comp) => {
        const diff = comp.updatedAt.getTime() - comp.createdAt.getTime();
        return acc + diff;
      }, 0);
      
      const avgMs = totalMs / resolvedItems.length;
      averageResolutionTimeHours = parseFloat((avgMs / (1000 * 60 * 60)).toFixed(2));
    }

    // Group counts by department
    const deptGroups = await prisma.complaint.groupBy({
      by: ['departmentId'],
      _count: { id: true }
    });

    // Fetch department mapping
    const departments = await prisma.department.findMany();
    const deptMap = {};
    departments.forEach((d) => {
      deptMap[d.id] = d.name;
    });

    const departmentStats = deptGroups.map((group) => ({
      departmentId: group.departmentId,
      departmentName: deptMap[group.departmentId] || 'Other/Admin',
      count: group._count.id
    }));

    // Group counts by category
    const catGroups = await prisma.complaint.groupBy({
      by: ['categoryId'],
      _count: { id: true }
    });

    // Fetch category mapping
    const categories = await prisma.category.findMany();
    const catMap = {};
    categories.forEach((c) => {
      catMap[c.id] = c.name;
    });

    const categoryStats = catGroups.map((group) => ({
      categoryId: group.categoryId,
      categoryName: catMap[group.categoryId] || 'Other/Cosmetic',
      count: group._count.id
    }));

    // Recent SLA breaches (last 7 days) for the dashboard "needs attention" list
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const recentSlaBreaches = await prisma.complaint.findMany({
      where: {
        isSlaBreached: true,
        updatedAt: { gte: sevenDaysAgo }
      },
      include: {
        // Aggregated analytics are readable by every role, so do NOT expose
        // submitter email here — name/picture is enough for the dashboard list.
        submittedBy: {
          select: { id: true, name: true, picture: true }
        },
        mediaItems: true
      },
      orderBy: { updatedAt: 'desc' },
      take: 10
    });
    await enrichComplaints(recentSlaBreaches);

    return sendSuccess(res, {
      totalComplaints,
      activeComplaints,
      resolvedComplaints,
      slaBreachedCount,
      averageResolutionTimeHours,
      departmentStats,
      categoryStats,
      recentSlaBreaches
    });

  } catch (error) {
    next(error);
  }
});

module.exports = router;
