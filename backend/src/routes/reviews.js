import express from 'express';
import { prisma } from '../server.js';

const router = express.Router();

// GET /api/reviews
router.get('/', async (req, res) => {
  try {
    const reviews = await prisma.review.findMany({
      include: {
        user: { select: { id: true, username: true, name: true } },
        project: { select: { id: true, name: true } },
        _count: { select: { comments: true } }
      },
      orderBy: { createdAt: 'desc' }
    });
    res.json(reviews);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch reviews' });
  }
});

// POST /api/reviews
router.post('/', async (req, res) => {
  try {
    const review = await prisma.review.create({
      data: {
        title: req.body.title || 'Code Review',
        description: req.body.description,
        oldCode: req.body.oldCode || '',
        newCode: req.body.newCode || '',
        language: req.body.language || 'JavaScript',
        projectId: req.body.projectId || 'default-project-id',
        userId: 'default-user-id',
        status: 'PENDING',
        riskLevel: 'LOW'
      }
    });
    res.status(201).json(review);
  } catch (error) {
    res.status(400).json({ error: 'Failed to create review' });
  }
});

export default router;
