const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('Seeding sample users and complaints into SCMS database...');

  // 1. Ensure reference data exists (Departments, Categories, Zones)
  // Fetch existing categories and departments
  const departments = await prisma.department.findMany();
  const categories = await prisma.category.findMany();
  const zones = await prisma.zone.findMany();

  if (departments.length === 0 || categories.length === 0) {
    console.error('Reference data (departments/categories) is missing. Please run npx prisma db seed first.');
    process.exit(1);
  }

  // Find some specific categories and departments to map
  const plumbingCat = categories.find(c => c.name === 'Plumbing') || categories[0];
  const electricalCat = categories.find(c => c.name === 'Electrical') || categories[0];
  const itCat = categories.find(c => c.name === 'IT/Network') || categories[0];
  const housekeepingCat = categories.find(c => c.name === 'Housekeeping') || categories[0];

  const civilDept = departments.find(d => d.code === 'CIVIL') || departments[0];
  const eeDept = departments.find(d => d.code === 'EE') || departments[0];
  const itDept = departments.find(d => d.code === 'IT') || departments[0];
  const hkDept = departments.find(d => d.code === 'HK') || departments[0];

  const hostelZone = zones.find(z => z.name.includes('Hostel')) || zones[0];
  const mainAcademicZone = zones.find(z => z.name.includes('Academic')) || zones[0];

  // 2. Create / Upsert Mock Users
  const usersToSeed = [
    {
      id: 'mock_role_user',
      googleId: 'google_mock_role_user',
      email: 'demo.user@rvce.edu.in',
      name: 'Demo Student',
      role: 'ROLE_USER',
      isApproved: true,
    },
    {
      id: 'mock_role_sr',
      googleId: 'google_mock_role_sr',
      email: 'demo.sr@rvce.edu.in',
      name: 'Demo SR (Representative)',
      role: 'ROLE_SR',
      isApproved: true,
    },
    {
      id: 'mock_role_staff',
      googleId: 'google_mock_role_staff',
      email: 'demo.staff@rvce.edu.in',
      name: 'Demo Maintenance Staff',
      role: 'ROLE_STAFF',
      isApproved: true,
      departmentId: eeDept.id
    },
    {
      id: 'mock_role_admin',
      googleId: 'google_mock_role_admin',
      email: 'demo.admin@rvce.edu.in',
      name: 'Demo Administrator',
      role: 'ROLE_ADMIN',
      isApproved: true,
    }
  ];

  for (const u of usersToSeed) {
    await prisma.user.upsert({
      where: { email: u.email },
      update: u,
      create: u
    });
  }
  console.log('Mock users seeded successfully.');

  // 3. Create Sample Complaints
  const complaintsToSeed = [
    {
      complaintNumber: 'COMP-2026-001',
      title: 'Water leakage in Boys Hostel bathroom',
      description: 'There is a major water leakage from the ceiling in the ground floor bathroom of Hostel Block A. The pipe appears broken and water is continuously pooling.',
      location: 'Hostel Block A, Ground Floor Bathroom',
      categoryId: plumbingCat.id,
      departmentId: civilDept.id,
      severity: 'HIGH',
      status: 'PENDING_SR_REVIEW',
      submittedById: 'mock_role_user',
      tags: ['Leakage', 'Water', 'Broken'],
      createdAt: new Date(Date.now() - 1000 * 60 * 60 * 2), // 2 hours ago
    },
    {
      complaintNumber: 'COMP-2026-002',
      title: 'Wi-Fi connection issues in library',
      description: 'The Wi-Fi network RVCE-WiFi is frequently disconnecting in the reading room. Speed is also very slow and it is difficult to open research articles.',
      location: 'Library Building, First Floor Reading Room',
      categoryId: itCat.id,
      departmentId: itDept.id,
      severity: 'MEDIUM',
      status: 'ASSIGNED',
      submittedById: 'mock_role_user',
      assignedToId: 'mock_role_staff',
      tags: ['Internet', 'Software'],
      createdAt: new Date(Date.now() - 1000 * 60 * 60 * 26), // 26 hours ago
    },
    {
      complaintNumber: 'COMP-2026-003',
      title: 'Broken fan in Class MCA-102',
      description: 'The middle fan in classroom MCA-102 makes a very loud rattling sound and moves extremely slowly. It is creating disturbance during lectures.',
      location: 'MCA Department Block, Room 102',
      categoryId: electricalCat.id,
      departmentId: eeDept.id,
      severity: 'LOW',
      status: 'RESOLVED',
      submittedById: 'mock_role_user',
      assignedToId: 'mock_role_staff',
      tags: ['Fan', 'Hardware'],
      createdAt: new Date(Date.now() - 1000 * 60 * 60 * 50), // 2 days ago
      updatedAt: new Date(Date.now() - 1000 * 60 * 60 * 5), // resolved 5 hours ago
    },
    {
      complaintNumber: 'COMP-2026-004',
      title: 'Power outage in MCA Computer Lab',
      description: 'The entire third row of desktops in the MCA computer lab is powered down. The MCB seems to have tripped due to overload.',
      location: 'MCA Department Block, 2nd Floor Lab',
      categoryId: electricalCat.id,
      departmentId: eeDept.id,
      severity: 'HIGH',
      status: 'CLOSED',
      submittedById: 'mock_role_user',
      assignedToId: 'mock_role_staff',
      tags: ['PowerOutage', 'AC'],
      rating: 5.0,
      ratingComment: 'The issue was fixed within 30 minutes. Extremely satisfied with the resolution!',
      createdAt: new Date(Date.now() - 1000 * 60 * 60 * 74), // 3 days ago
      updatedAt: new Date(Date.now() - 1000 * 60 * 60 * 73), // resolved/closed 3.05 days ago
    },
    {
      complaintNumber: 'COMP-2026-005',
      title: 'Cleanliness issue in Mess hall',
      description: 'The dining tables in Mess Hall B are not being wiped clean between lunch batches. Fly infestation is starting to occur near the wash basin.',
      location: 'Mess Committee, Dining Area B',
      categoryId: housekeepingCat.id,
      departmentId: hkDept.id,
      severity: 'HIGH',
      status: 'IN_PROGRESS',
      submittedById: 'mock_role_user',
      assignedToId: 'mock_role_staff',
      tags: ['Cleanliness', 'Water'],
      createdAt: new Date(Date.now() - 1000 * 60 * 60 * 12), // 12 hours ago
    }
  ];

  for (const c of complaintsToSeed) {
    await prisma.complaint.upsert({
      where: { complaintNumber: c.complaintNumber },
      update: c,
      create: c
    });
  }

  console.log('Sample complaints seeded successfully!');
}

main()
  .catch((e) => {
    console.error('Error seeding sample data:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
