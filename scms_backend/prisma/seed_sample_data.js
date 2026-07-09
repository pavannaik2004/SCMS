const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// Real photos that already exist under scms_backend/Storage so the demo renders
// actual images instead of broken links.
const ORIGINAL_PHOTO = '/Storage/media-1783185120587-256222548.jpg';
const PROOF_PHOTO = '/Storage/media-1783403981360-392612853.jpg';

const HOUR = 1000 * 60 * 60;

async function main() {
  console.log('Seeding demo users and complaints into SCMS database...');

  const departments = await prisma.department.findMany();
  const categories = await prisma.category.findMany();
  const zones = await prisma.zone.findMany();

  if (departments.length === 0 || categories.length === 0) {
    console.error('Reference data (departments/categories) is missing. Run `node prisma/seed.js` first.');
    process.exit(1);
  }

  const catByName = Object.fromEntries(categories.map((c) => [c.name, c]));
  const deptByCode = Object.fromEntries(departments.map((d) => [d.code, d]));
  const zoneByHint = (hint) => zones.find((z) => z.name.toLowerCase().includes(hint)) || zones[0];

  // ---------------------------------------------------------------------------
  // 1. Demo users — 5 students, 4 staff, 3 SRs, 1 admin (real-sounding names).
  //    Ids are deterministic so the dev-login picker + complaints reference them.
  // ---------------------------------------------------------------------------
  const students = [
    { id: 'demo-student-aarav', name: 'Aarav Sharma', email: 'aarav.sharma@rvce.edu.in' },
    { id: 'demo-student-diya', name: 'Diya Nair', email: 'diya.nair@rvce.edu.in' },
    { id: 'demo-student-rohan', name: 'Rohan Reddy', email: 'rohan.reddy@rvce.edu.in' },
    { id: 'demo-student-ananya', name: 'Ananya Iyer', email: 'ananya.iyer@rvce.edu.in' },
    { id: 'demo-student-karthik', name: 'Karthik Rao', email: 'karthik.rao@rvce.edu.in' }
  ].map((u) => ({ ...u, role: 'ROLE_USER' }));

  const staff = [
    { id: 'demo-staff-electrical', name: 'Suresh Kumar', email: 'suresh.kumar@rvce.edu.in', deptCode: 'EE' },
    { id: 'demo-staff-civil', name: 'Ramesh Gowda', email: 'ramesh.gowda@rvce.edu.in', deptCode: 'CIVIL' },
    { id: 'demo-staff-it', name: 'Anil Mehta', email: 'anil.mehta@rvce.edu.in', deptCode: 'IT' },
    { id: 'demo-staff-housekeeping', name: 'Lakshmi Devi', email: 'lakshmi.devi@rvce.edu.in', deptCode: 'HK' }
  ].map((u) => ({ ...u, role: 'ROLE_STAFF', departmentId: deptByCode[u.deptCode] ? deptByCode[u.deptCode].id : null }));

  const srs = [
    { id: 'demo-sr-first', name: 'Vikram Singh (First Year SR)', email: 'vikram.sr1@rvce.edu.in' },
    { id: 'demo-sr-second', name: 'Priya Menon (Second Year SR)', email: 'priya.sr2@rvce.edu.in' },
    { id: 'demo-sr-third', name: 'Arjun Pillai (Third Year SR)', email: 'arjun.sr3@rvce.edu.in' }
  ].map((u) => ({ ...u, role: 'ROLE_SR' }));

  const admin = { id: 'demo-admin', name: 'Dr. Nagaraj Bhat', email: 'admin@rvce.edu.in', role: 'ROLE_ADMIN' };

  const allUsers = [...students, ...staff, ...srs, admin];

  for (const u of allUsers) {
    const data = {
      id: u.id,
      googleId: `google_${u.id}`,
      email: u.email,
      name: u.name,
      role: u.role,
      departmentId: u.departmentId || null,
      isApproved: true
    };
    await prisma.user.upsert({ where: { email: u.email }, update: data, create: data });
  }
  const userById = Object.fromEntries(allUsers.map((u) => [u.id, u]));
  console.log(`Seeded ${allUsers.length} demo users.`);

  // ---------------------------------------------------------------------------
  // 2. Twenty complaints spread across every lifecycle stage.
  //    stage drives the status, timeline, proof media, rating & timestamps.
  // ---------------------------------------------------------------------------
  const pick = (arr, i) => arr[i % arr.length];

  const specs = [
    // --- PENDING_SR_REVIEW (3) ---
    { stage: 'PENDING_SR_REVIEW', student: 'demo-student-aarav', cat: 'Plumbing', dept: 'CIVIL', sev: 'HIGH', zone: 'hostel', title: 'Water leakage in Boys Hostel bathroom', desc: 'Major water leakage from the ceiling of the ground-floor bathroom in Hostel Block A. A pipe appears broken and water is pooling continuously.', loc: 'Hostel Block A, Ground Floor Bathroom', tags: ['Leakage', 'Water', 'Broken'], age: 3 },
    { stage: 'PENDING_SR_REVIEW', student: 'demo-student-diya', cat: 'Housekeeping', dept: 'HK', sev: 'MEDIUM', zone: 'academic', title: 'Overflowing dustbins near canteen', desc: 'The dustbins outside the main canteen have not been cleared for two days and are overflowing, attracting flies.', loc: 'Main Academic Block, Canteen Area', tags: ['Cleanliness'], age: 6 },
    { stage: 'PENDING_SR_REVIEW', student: 'demo-student-rohan', cat: 'IT/Network', dept: 'IT', sev: 'LOW', zone: 'library', title: 'Projector remote not working in seminar hall', desc: 'The projector remote in the seminar hall is unresponsive; batteries seem dead and no spare is available.', loc: 'Library Building, Seminar Hall', tags: ['Hardware'], age: 10 },

    // --- OPEN (3) : SR approved, awaiting admin assignment ---
    { stage: 'OPEN', student: 'demo-student-ananya', cat: 'Electrical', dept: 'EE', sev: 'HIGH', sr: 'demo-sr-first', zone: 'mca', title: 'Frequent power trips in MCA lab', desc: 'The MCA computer lab loses power several times a day, interrupting practical sessions. The MCB trips under load.', loc: 'MCA Department Block, 2nd Floor Lab', tags: ['PowerOutage'], age: 20 },
    { stage: 'OPEN', student: 'demo-student-karthik', cat: 'Civil', dept: 'CIVIL', sev: 'MEDIUM', sr: 'demo-sr-second', zone: 'hostel', title: 'Cracked window pane in Hostel Block B', desc: 'A window pane in room 214 of Hostel Block B is cracked and could shatter. Needs replacement before the monsoon.', loc: 'Hostel Block B, Room 214', tags: ['Broken', 'Safety'], age: 26 },
    { stage: 'OPEN', student: 'demo-student-aarav', cat: 'Mess/Cafeteria', dept: 'MESS', sev: 'MEDIUM', sr: 'demo-sr-third', zone: 'academic', title: 'Cold food served at dinner', desc: 'Dinner is being served cold in Mess Hall B for the past week. The food warmers appear to be switched off early.', loc: 'Mess Committee, Dining Area B', tags: ['Noise'], age: 30 },

    // --- ASSIGNED (3) : admin assigned a staff member ---
    { stage: 'ASSIGNED', student: 'demo-student-diya', cat: 'IT/Network', dept: 'IT', sev: 'MEDIUM', sr: 'demo-sr-first', staff: 'demo-staff-it', zone: 'library', title: 'Wi-Fi disconnecting in reading room', desc: 'The RVCE-WiFi network keeps disconnecting in the library reading room and speeds are very slow for research articles.', loc: 'Library Building, First Floor Reading Room', tags: ['Internet', 'Software'], age: 28 },
    { stage: 'ASSIGNED', student: 'demo-student-rohan', cat: 'Electrical', dept: 'EE', sev: 'LOW', sr: 'demo-sr-second', staff: 'demo-staff-electrical', zone: 'mca', title: 'Tube light flickering in MCA-101', desc: 'The tube light near the whiteboard in MCA-101 flickers constantly and strains the eyes during lectures.', loc: 'MCA Department Block, Room 101', tags: ['Light'], age: 34 },
    { stage: 'ASSIGNED', student: 'demo-student-ananya', cat: 'Plumbing', dept: 'CIVIL', sev: 'MEDIUM', sr: 'demo-sr-third', staff: 'demo-staff-civil', zone: 'academic', title: 'Blocked wash basin in ladies restroom', desc: 'The wash basin in the ground-floor ladies restroom of the academic block is blocked and water drains very slowly.', loc: 'Main Academic Block, Ground Floor Restroom', tags: ['Water', 'Leakage'], age: 38 },

    // --- IN_PROGRESS (3) : staff started working ---
    { stage: 'IN_PROGRESS', student: 'demo-student-karthik', cat: 'Housekeeping', dept: 'HK', sev: 'HIGH', sr: 'demo-sr-first', staff: 'demo-staff-housekeeping', zone: 'academic', title: 'Cleanliness issue in Mess hall', desc: 'Dining tables in Mess Hall B are not wiped between lunch batches and a fly problem is starting near the wash basin.', loc: 'Mess Committee, Dining Area B', tags: ['Cleanliness', 'Water'], age: 40 },
    { stage: 'IN_PROGRESS', student: 'demo-student-aarav', cat: 'Electrical', dept: 'EE', sev: 'HIGH', sr: 'demo-sr-second', staff: 'demo-staff-electrical', zone: 'hostel', title: 'No power in Hostel Block A wing', desc: 'The entire east wing of Hostel Block A has had no power since morning. Students are unable to charge devices or study.', loc: 'Hostel Block A, East Wing', tags: ['PowerOutage'], age: 44 },
    { stage: 'IN_PROGRESS', student: 'demo-student-diya', cat: 'IT/Network', dept: 'IT', sev: 'MEDIUM', sr: 'demo-sr-third', staff: 'demo-staff-it', zone: 'mca', title: 'Lab desktop not booting', desc: 'Desktop number 12 in the MCA lab does not boot past the BIOS screen; it may have a failing hard disk.', loc: 'MCA Department Block, 2nd Floor Lab', tags: ['Hardware'], age: 48 },

    // --- RESOLVED (3) : staff submitted proof, awaiting admin verification ---
    { stage: 'RESOLVED', student: 'demo-student-rohan', cat: 'Electrical', dept: 'EE', sev: 'LOW', sr: 'demo-sr-first', staff: 'demo-staff-electrical', zone: 'mca', title: 'Broken fan in Class MCA-102', desc: 'The middle fan in MCA-102 rattles loudly and rotates slowly, disturbing lectures.', loc: 'MCA Department Block, Room 102', tags: ['Fan', 'Hardware'], age: 52 },
    { stage: 'RESOLVED', student: 'demo-student-ananya', cat: 'Plumbing', dept: 'CIVIL', sev: 'MEDIUM', sr: 'demo-sr-second', staff: 'demo-staff-civil', zone: 'hostel', title: 'Leaking tap in hostel common bathroom', desc: 'A tap in the Hostel Block B common bathroom does not shut fully and wastes water all day.', loc: 'Hostel Block B, Common Bathroom', tags: ['Leakage', 'Water'], age: 56 },
    { stage: 'RESOLVED', student: 'demo-student-karthik', cat: 'Housekeeping', dept: 'HK', sev: 'LOW', sr: 'demo-sr-third', staff: 'demo-staff-housekeeping', zone: 'library', title: 'Dusty shelves in library stack room', desc: 'The reference stack room in the library is very dusty and needs a thorough cleaning.', loc: 'Library Building, Stack Room', tags: ['Cleanliness'], age: 60 },

    // --- COMPLETED (2) : admin verified; one awaiting rating ---
    { stage: 'COMPLETED', student: 'demo-student-aarav', cat: 'IT/Network', dept: 'IT', sev: 'MEDIUM', sr: 'demo-sr-first', staff: 'demo-staff-it', zone: 'mca', title: 'Printer out of order in MCA office', desc: 'The shared printer in the MCA department office jams on every print and needs servicing.', loc: 'MCA Department Block, Department Office', tags: ['Hardware'], age: 70 },
    { stage: 'COMPLETED', student: 'demo-student-diya', cat: 'Civil', dept: 'CIVIL', sev: 'LOW', sr: 'demo-sr-second', staff: 'demo-staff-civil', zone: 'academic', title: 'Loose door handle in classroom', desc: 'The door handle of the academic block classroom AB-05 is loose and about to come off.', loc: 'Main Academic Block, Room AB-05', tags: ['Broken', 'Furniture'], age: 74 },

    // --- CLOSED (2) : completed and rated by the student ---
    { stage: 'CLOSED', student: 'demo-student-rohan', cat: 'Electrical', dept: 'EE', sev: 'HIGH', sr: 'demo-sr-third', staff: 'demo-staff-electrical', zone: 'mca', title: 'Power outage in MCA Computer Lab', desc: 'The third row of desktops in the MCA lab was powered down after the MCB tripped due to overload.', loc: 'MCA Department Block, 2nd Floor Lab', tags: ['PowerOutage', 'AC'], rating: 5, ratingComment: 'Fixed within 30 minutes. Extremely satisfied with the quick resolution!', age: 96 },
    { stage: 'CLOSED', student: 'demo-student-ananya', cat: 'Housekeeping', dept: 'HK', sev: 'MEDIUM', sr: 'demo-sr-first', staff: 'demo-staff-housekeeping', zone: 'hostel', title: 'Garbage not collected in hostel', desc: 'Garbage from the Hostel Block A pantry had not been collected for three days and was smelling.', loc: 'Hostel Block A, Pantry', tags: ['Cleanliness'], rating: 4, ratingComment: 'Cleared well, though it took a day longer than expected.', age: 110 },

    // --- REJECTED (1) : SR rejected the complaint ---
    { stage: 'REJECTED', student: 'demo-student-karthik', cat: 'Other', dept: 'ADMIN', sev: 'LOW', sr: 'demo-sr-second', zone: 'academic', title: 'Request for extra holiday', desc: 'Requesting an additional holiday next Friday for personal reasons.', loc: 'Main Academic Block', tags: [], srCause: 'This is not a maintenance complaint. Please raise leave requests through the academic office.', age: 80 }
  ];

  // Progression order used to build a plausible timeline up to each stage.
  const FLOW = ['PENDING_SR_REVIEW', 'OPEN', 'ASSIGNED', 'IN_PROGRESS', 'RESOLVED', 'COMPLETED', 'CLOSED'];

  let seq = 0;
  for (const s of specs) {
    seq += 1;
    const complaintNumber = `SCMS-2026-${String(seq).padStart(5, '0')}`;
    const cat = catByName[s.cat] || categories[0];
    const dept = deptByCode[s.dept] || departments[0];
    const zone = zoneByHint(s.zone);
    const createdAt = new Date(Date.now() - s.age * HOUR);
    const student = userById[s.student];
    const staff = s.staff ? userById[s.staff] : null;
    const sr = s.sr ? userById[s.sr] : null;

    const isRejected = s.stage === 'REJECTED';
    const flowIndex = isRejected ? 0 : FLOW.indexOf(s.stage);

    // Derived lifecycle timestamps.
    const reachedResolved = !isRejected && flowIndex >= FLOW.indexOf('RESOLVED');
    const reachedCompleted = !isRejected && flowIndex >= FLOW.indexOf('COMPLETED');
    const resolvedAt = reachedResolved ? new Date(createdAt.getTime() + Math.min(s.age - 2, 6) * HOUR) : null;
    const completedAt = reachedCompleted ? new Date(createdAt.getTime() + Math.min(s.age - 1, 7) * HOUR) : null;

    const complaintData = {
      complaintNumber,
      title: s.title,
      description: s.desc,
      location: s.loc,
      categoryId: cat.id,
      departmentId: dept.id,
      severity: s.sev,
      status: s.stage,
      tags: s.tags,
      submittedById: student.id,
      assignedToId: staff ? staff.id : null,
      reviewedBySrId: (sr && (flowIndex >= FLOW.indexOf('OPEN') || isRejected)) ? sr.id : null,
      srRejectionCause: isRejected ? s.srCause : null,
      slaDeadline: flowIndex >= FLOW.indexOf('OPEN') ? new Date(createdAt.getTime() + 48 * HOUR) : null,
      rating: s.rating != null ? s.rating : null,
      ratingComment: s.ratingComment || null,
      resolvedAt,
      completedAt,
      gpsPlaceName: zone.name,
      createdAt
    };

    const complaint = await prisma.complaint.upsert({
      where: { complaintNumber },
      update: complaintData,
      create: complaintData
    });

    // Rebuild child rows so re-running the seed stays idempotent.
    await prisma.mediaItem.deleteMany({ where: { complaintId: complaint.id } });
    await prisma.complaintUpdate.deleteMany({ where: { complaintId: complaint.id } });

    // Media: an original submission photo, plus proof media once resolved.
    const media = [{
      complaintId: complaint.id,
      url: ORIGINAL_PHOTO,
      mediaType: 'IMAGE',
      purpose: 'ORIGINAL',
      gpsLatitude: 12.9237,
      gpsLongitude: 77.4987,
      gpsPlaceName: zone.name,
      capturedAt: createdAt,
      fileSizeBytes: 245000,
      isWatermarked: true
    }];
    if (reachedResolved) {
      media.push({
        complaintId: complaint.id,
        url: PROOF_PHOTO,
        mediaType: 'IMAGE',
        purpose: 'PROOF',
        gpsLatitude: 0.0,
        gpsLongitude: 0.0,
        gpsPlaceName: 'Resolution Proof',
        capturedAt: resolvedAt,
        fileSizeBytes: 262000,
        isWatermarked: true
      });
    }
    await prisma.mediaItem.createMany({ data: media });

    // Build the timeline chain up to the current stage.
    const updates = [];
    const addUpdate = (actor, prev, next, notes, at) => updates.push({
      complaintId: complaint.id,
      updatedById: actor.id,
      updatedByName: actor.name,
      updatedByRole: actor.role,
      previousStatus: prev,
      newStatus: next,
      notes,
      timestamp: at
    });

    // Submission is always first.
    addUpdate(student, 'SUBMITTED', 'PENDING_SR_REVIEW', 'Complaint submitted. Pending Student Representative review.', createdAt);

    if (isRejected) {
      addUpdate(sr, 'PENDING_SR_REVIEW', 'REJECTED', s.srCause, new Date(createdAt.getTime() + 2 * HOUR));
    } else {
      const stepAt = (i) => new Date(createdAt.getTime() + (i + 1) * HOUR);
      if (flowIndex >= FLOW.indexOf('OPEN')) {
        addUpdate(sr || admin, 'PENDING_SR_REVIEW', 'OPEN', 'SR approved the complaint. Registered for resolution.', stepAt(0));
      }
      if (flowIndex >= FLOW.indexOf('ASSIGNED') && staff) {
        addUpdate(admin, 'OPEN', 'ASSIGNED', `Assigned to staff member ${staff.name}.`, stepAt(1));
      }
      if (flowIndex >= FLOW.indexOf('IN_PROGRESS') && staff) {
        addUpdate(staff, 'ASSIGNED', 'IN_PROGRESS', 'Staff started working on the complaint.', stepAt(2));
      }
      if (flowIndex >= FLOW.indexOf('RESOLVED') && staff) {
        addUpdate(staff, 'IN_PROGRESS', 'RESOLVED', 'Staff submitted proof of resolution. Awaiting admin verification.', resolvedAt);
      }
      if (flowIndex >= FLOW.indexOf('COMPLETED')) {
        addUpdate(admin, 'RESOLVED', 'COMPLETED', 'Admin verified the resolution. Complaint completed.', completedAt);
      }
      if (flowIndex >= FLOW.indexOf('CLOSED')) {
        addUpdate(student, 'COMPLETED', 'CLOSED', `User submitted a rating of ${s.rating}/5 stars.`, new Date(completedAt.getTime() + 1 * HOUR));
      }
    }

    await prisma.complaintUpdate.createMany({ data: updates });
  }

  console.log(`Seeded ${specs.length} demo complaints with timelines and proof media.`);
}

main()
  .catch((e) => {
    console.error('Error seeding sample data:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
