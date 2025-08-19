import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../server';

const router = Router();

const createProjectSchema = z.object({
  name: z.string().min(1),
  description: z.string().optional(),
  githubUrl: z.string().url().optional(),
  language: z.string().optional(),
  isPrivate: z.boolean().default(false)
});

// GET /api/projects - Список проектов
router.get('/', async (req, res) => {
  try {
    const projects = await prisma.project.findMany({
      include: {
        user: {
          select: { id: true, username: true, name: true }
        },
        _count: {
          select: { reviews: true }
        }
      },
      orderBy: { updatedAt: 'desc' }
    });
    
    res.json(projects);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch projects' });
  }
});

// POST /api/projects - Создание проекта
router.post('/', async (req, res) => {
  try {
    const data = createProjectSchema.parse(req.body);
    
    const project = await prisma.project.create({
      data: {
        ...data,
        userId: req.user?.id || 'temp-user-id', // TODO: Get from JWT
      },
      include: {
        user: {
          select: { id: true, username: true, name: true }
        }
      }
    });
    
    res.status(201).json(project);
  } catch (error) {
    res.status(400).json({ error: 'Failed to create project' });
  }
});

// GET /api/projects/:id - Детали проекта
router.get('/:id', async (req, res) => {
  try {
    const project = await prisma.project.findUnique({
      where: { id: req.params.id },
      include: {
        user: {
          select: { id: true, username: true, name: true }
        },
        reviews: {
          orderBy: { createdAt: 'desc' },
          take: 10
        }
      }
    });
    
    if (!project) {
      return res.status(404).json({ error: 'Project not found' });
    }
    
    res.json(project);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch project' });
  }
});

export default router;
