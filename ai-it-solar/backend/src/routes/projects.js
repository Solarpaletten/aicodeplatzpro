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
    console.error('Projects GET error:', error);
    res.status(500).json({ error: 'Failed to fetch projects' });
  }
});

// POST /api/projects
router.post('/', async (req, res) => {
  try {
    console.log('Creating project with data:', req.body);
    
    const project = await prisma.project.create({
      data: {
        name: req.body.name || 'Unnamed Project',
        description: req.body.description || null,
        githubUrl: req.body.githubUrl || null,
        language: req.body.language || 'JavaScript',
        isPrivate: req.body.isPrivate || false,
        userId: 'default-user-id'
      },
      include: {
        user: { select: { id: true, username: true, name: true } }
      }
    });
    
    console.log('Project created successfully:', project);
    res.status(201).json(project);
  } catch (error) {
    console.error('Project creation error:', error);
    res.status(400).json({ 
      error: 'Failed to create project',
      details: error.message 
    });
  }
});

export default router;
