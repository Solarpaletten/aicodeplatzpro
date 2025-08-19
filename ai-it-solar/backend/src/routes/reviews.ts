import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../server';

const router = Router();

const createReviewSchema = z.object({
  title: z.string().min(1),
  description: z.string().optional(),
  oldCode: z.string(),
  newCode: z.string(),
  language: z.string(),
  projectId: z.string()
});

// GET /api/reviews - Список ревью
router.get('/', async (req, res) => {
  try {
    const reviews = await prisma.review.findMany({
      include: {
        user: {
          select: { id: true, username: true, name: true }
        },
        project: {
          select: { id: true, name: true }
        },
        _count: {
          select: { comments: true }
        }
      },
      orderBy: { createdAt: 'desc' }
    });
    
    res.json(reviews);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch reviews' });
  }
});

// POST /api/reviews - Создание ревью
router.post('/', async (req, res) => {
  try {
    const data = createReviewSchema.parse(req.body);
    
    // Простой анализ кода (без AI пока)
    const oldLines = data.oldCode.split('\n');
    const newLines = data.newCode.split('\n');
    const maxLines = Math.max(oldLines.length, newLines.length);
    
    let changedLines = 0;
    let functionsChanged = 0;
    let importsChanged = 0;
    
    for (let i = 0; i < maxLines; i++) {
      const oldLine = oldLines[i] || '';
      const newLine = newLines[i] || '';
      
      if (oldLine !== newLine) {
        changedLines++;
        
        // Простая детекция функций
        if (oldLine.match(/function|def|class/) || newLine.match(/function|def|class/)) {
          functionsChanged++;
        }
        
        // Простая детекция импортов
        if (oldLine.match(/import|from|require/) || newLine.match(/import|from|require/)) {
          importsChanged++;
        }
      }
    }
    
    // Определение уровня риска
    const changePercent = (changedLines / maxLines) * 100;
    let riskLevel = 'LOW';
    if (changePercent > 50 || functionsChanged > 5) riskLevel = 'HIGH';
    else if (changePercent > 25 || functionsChanged > 2) riskLevel = 'MEDIUM';
    
    const review = await prisma.review.create({
      data: {
        ...data,
        userId: req.user?.id || 'temp-user-id', // TODO: Get from JWT
        riskLevel: riskLevel as any,
        linesChanged: changedLines,
        functionsChanged,
        importsChanged,
        analysisData: {
          totalLines: maxLines,
          changedLines,
          changePercent: Math.round(changePercent),
          riskFactors: {
            functionsChanged,
            importsChanged,
            largeChanges: changePercent > 50
          }
        }
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
    console.error('Review creation error:', error);
    res.status(400).json({ error: 'Failed to create review' });
  }
});

// GET /api/reviews/:id - Детали ревью
router.get('/:id', async (req, res) => {
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
        comments: {
          include: {
            user: {
              select: { id: true, username: true, name: true }
            }
          },
          orderBy: { createdAt: 'asc' }
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
