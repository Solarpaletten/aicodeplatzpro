#!/bin/bash

echo "🔧 Fixing TypeScript errors..."

# 1. Создаем типы для Express Request
cat > backend/src/types/express.d.ts << 'EOF'
import { Request } from 'express';

declare global {
  namespace Express {
    interface Request {
      user?: {
        id: string;
        username: string;
        email: string;
      };
    }
  }
}
EOF

# 2. Исправляем projects.ts
cat > backend/src/routes/projects.ts << 'EOF'
import { Router, Request, Response } from 'express';
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
router.get('/', async (req: Request, res: Response) => {
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
router.post('/', async (req: Request, res: Response) => {
  try {
    const data = createProjectSchema.parse(req.body);
    
    const project = await prisma.project.create({
      data: {
        ...data,
        userId: req.user?.id || 'default-user-id',
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
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const project = await prisma.project.findUnique({
      where: { id: req.params.id },
      include: {
        user: {
          select: { id: true, username: true, name: true }
        },
        reviews: {
          include: {
            user: {
              select: { id: true, username: true, name: true }
            }
          },
          orderBy: { createdAt: 'desc' }
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
EOF

# 3. Исправляем reviews.ts
cat > backend/src/routes/reviews.ts << 'EOF'
import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { prisma } from '../server';

const router = Router();

const createReviewSchema = z.object({
  projectId: z.string(),
  oldCode: z.string(),
  newCode: z.string(),
  description: z.string().optional(),
});

// GET /api/reviews - Список ревью
router.get('/', async (req: Request, res: Response) => {
  try {
    const reviews = await prisma.review.findMany({
      include: {
        user: {
          select: { id: true, username: true, name: true }
        },
        project: {
          select: { id: true, name: true }
        },
        suggestions: true
      },
      orderBy: { createdAt: 'desc' }
    });
    
    res.json(reviews);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch reviews' });
  }
});

// POST /api/reviews - Создание ревью
router.post('/', async (req: Request, res: Response) => {
  try {
    const data = createReviewSchema.parse(req.body);
    
    const review = await prisma.review.create({
      data: {
        ...data,
        userId: req.user?.id || 'default-user-id',
        status: 'PENDING',
      },
      include: {
        user: {
          select: { id: true, username: true, name: true }
        },
        project: {
          select: { id: true, name: true }
        }
      }
    });
    
    res.status(201).json(review);
  } catch (error) {
    res.status(400).json({ error: 'Failed to create review' });
  }
});

// GET /api/reviews/:id - Детали ревью
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const review = await prisma.review.findUnique({
      where: { id: req.params.id },
      include: {
        user: {
          select: { id: true, username: true, name: true }
        },
        project: {
          select: { id: true, name: true }
        },
        suggestions: {
          orderBy: { createdAt: 'desc' }
        }
      }
    });
    
    if (!review) {
      return res.status(404).json({ error: 'Review not found' });
    }
    
    res.json(review);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch review' });
  }
});

export default router;
EOF

echo "✅ TypeScript errors fixed!"
echo "🚀 Now run: ./deploy.sh"