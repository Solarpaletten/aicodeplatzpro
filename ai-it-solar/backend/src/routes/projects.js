import express from 'express';
import { prisma } from '../server.js';

const router = express.Router();

// GET /api/projects
router.get('/', async (req, res) => {
  try {
    const projects = await prisma.project.findMany({
      include: {
        user: { select: { id: true, username: true, name: true } },
        _count: { select: { reviews: true } }
      },
      orderBy: { updatedAt: 'desc' }
    });
    res.json(projects);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch projects' });
  }
});

// POST /api/projects
router.post('/', async (req, res) => {
  try {
    const project = await prisma.project.create({
      data: {
        name: req.body.name || 'Demo Project',
        description: req.body.description,
        githubUrl: req.body.githubUrl,
        language: req.body.language || 'JavaScript',
        userId: 'default-user-id'
      }
    });
    res.status(201).json(project);
  } catch (error) {
    res.status(400).json({ error: 'Failed to create project' });
  }
});

export default router;
