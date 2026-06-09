const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('Seeding SCMS database...');

  // 1. Seed Allowed Login Domains
  await prisma.allowedDomain.upsert({
    where: { domain: 'rvce.edu.in' },
    update: {},
    create: {
      domain: 'rvce.edu.in',
      description: 'RV College of Engineering Domain'
    }
  });

  // 2. Seed Departments
  const departments = [
    { name: 'Electrical Department', code: 'EE' },
    { name: 'Civil & Maintenance Department', code: 'CIVIL' },
    { name: 'IT Department', code: 'IT' },
    { name: 'Housekeeping Department', code: 'HK' },
    { name: 'Security Department', code: 'SEC' },
    { name: 'Mess Committee', code: 'MESS' },
    { name: 'Transport Department', code: 'TRANS' },
    { name: 'Library Department', code: 'LIB' },
    { name: 'Sports Department', code: 'SPORTS' },
    { name: 'Administration', code: 'ADMIN' }
  ];

  const deptMap = {};
  for (const dept of departments) {
    const created = await prisma.department.upsert({
      where: { code: dept.code },
      update: {},
      create: dept
    });
    deptMap[dept.name] = created.id;
  }

  // 3. Seed Categories and map them to default resolving departments
  const categories = [
    { name: 'Electrical', defaultDept: 'Electrical Department' },
    { name: 'Plumbing', defaultDept: 'Civil & Maintenance Department' },
    { name: 'Civil', defaultDept: 'Civil & Maintenance Department' },
    { name: 'IT/Network', defaultDept: 'IT Department' },
    { name: 'Housekeeping', defaultDept: 'Housekeeping Department' },
    { name: 'Security', defaultDept: 'Security Department' },
    { name: 'Mess/Cafeteria', defaultDept: 'Mess Committee' },
    { name: 'Transport', defaultDept: 'Transport Department' },
    { name: 'Library', defaultDept: 'Library Department' },
    { name: 'Sports', defaultDept: 'Sports Department' },
    { name: 'Other', defaultDept: 'Administration' }
  ];

  for (const cat of categories) {
    const defaultDeptId = deptMap[cat.defaultDept];
    await prisma.category.upsert({
      where: { name: cat.name },
      update: {},
      create: {
        name: cat.name,
        defaultDepartmentId: defaultDeptId,
        iconName: cat.name.toLowerCase()
      }
    });
  }

  // 4. Seed Campus Zones
  const zones = [
    { name: 'Hostel Block A', description: 'Boys Hostel A Block' },
    { name: 'Hostel Block B', description: 'Boys Hostel B Block' },
    { name: 'Main Academic Block', description: 'Main administrative and classroom buildings' },
    { name: 'MCA Department Block', description: 'MCA classrooms and lab building' },
    { name: 'Library Building', description: 'Campus central library' },
    { name: 'Sports Complex', description: 'Indoor stadium and gymkhana' }
  ];

  for (const zone of zones) {
    await prisma.zone.upsert({
      where: { name: zone.name },
      update: {},
      create: zone
    });
  }

  // 5. Seed Predefined Tags
  const tags = [
    'Leakage', 'Broken', 'PowerOutage', 'Internet', 'Cleanliness', 
    'Safety', 'Noise', 'Hardware', 'Software', 'Furniture', 
    'Light', 'Water', 'Fan', 'AC'
  ];

  for (const tag of tags) {
    await prisma.tag.upsert({
      where: { name: tag },
      update: {},
      create: { name: tag }
    });
  }

  console.log('SCMS Database seeded successfully!');
}

main()
  .catch((e) => {
    console.error('Error seeding database:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
