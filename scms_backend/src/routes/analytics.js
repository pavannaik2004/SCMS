const express = require('express');
const { PrismaClient } = require('@prisma/client');
const { sendSuccess } = require('../utils/responseHelper');
const authenticate = require('../middleware/authenticate');
const requireRole = require('../middleware/requireRole');

const router = express.Router();
const prisma = new PrismaClient();

// Guard route to privileged roles
router.use(authenticate);
router.use(requireRole('ROLE_ADMIN', 'ROLE_DEPT_HEAD'));

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

    return sendSuccess(res, {
      totalComplaints,
      activeComplaints,
      resolvedComplaints,
      slaBreachedCount,
      averageResolutionTimeHours,
      departmentStats,
      categoryStats
    });

  } catch (error) {
    next(error);
  }
});

module.exports = router;
