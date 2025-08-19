#!/bin/bash

echo "🔧 AI IT Solar - Fixing TypeScript errors..."

cd backend

# 1. Добавляем недостающие @types
echo "📦 Installing missing types..."
npm install --save-dev @types/morgan @types/compression

# 2. Создаем недостающие route файлы
echo "📁 Creating missing route files..."

# Projects route
cat > src/routes/projects.ts << 'EOF'
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
EOF

# Reviews route
cat > src/routes/reviews.ts << 'EOF'
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
EOF

# GitHub route
cat > src/routes/github.ts << 'EOF'
import { Router } from 'express';
import { Octokit } from '@octokit/rest';

const router = Router();

// Инициализация GitHub API клиента
const getOctokit = (token?: string) => {
  return new Octokit({
    auth: token || process.env.GITHUB_TOKEN,
  });
};

// GET /api/github/repos - Репозитории пользователя
router.get('/repos', async (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({ error: 'GitHub token required' });
    }
    
    const octokit = getOctokit(token);
    const { data: repos } = await octokit.rest.repos.listForAuthenticatedUser({
      sort: 'updated',
      per_page: 50
    });
    
    const formattedRepos = repos.map(repo => ({
      id: repo.id,
      name: repo.name,
      fullName: repo.full_name,
      description: repo.description,
      language: repo.language,
      private: repo.private,
      htmlUrl: repo.html_url,
      updatedAt: repo.updated_at
    }));
    
    res.json(formattedRepos);
  } catch (error) {
    console.error('GitHub repos error:', error);
    res.status(500).json({ error: 'Failed to fetch repositories' });
  }
});

// GET /api/github/commits/:owner/:repo - Коммиты репозитория
router.get('/commits/:owner/:repo', async (req, res) => {
  try {
    const { owner, repo } = req.params;
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    const octokit = getOctokit(token);
    const { data: commits } = await octokit.rest.repos.listCommits({
      owner,
      repo,
      per_page: 20
    });
    
    const formattedCommits = commits.map(commit => ({
      sha: commit.sha,
      message: commit.commit.message,
      author: commit.commit.author,
      date: commit.commit.author?.date,
      htmlUrl: commit.html_url
    }));
    
    res.json(formattedCommits);
  } catch (error) {
    console.error('GitHub commits error:', error);
    res.status(500).json({ error: 'Failed to fetch commits' });
  }
});

// POST /api/github/compare - Сравнение коммитов
router.post('/compare', async (req, res) => {
  try {
    const { owner, repo, base, head } = req.body;
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    const octokit = getOctokit(token);
    const { data: comparison } = await octokit.rest.repos.compareCommits({
      owner,
      repo,
      base,
      head
    });
    
    res.json({
      status: comparison.status,
      ahead_by: comparison.ahead_by,
      behind_by: comparison.behind_by,
      total_commits: comparison.total_commits,
      files: comparison.files?.map(file => ({
        filename: file.filename,
        status: file.status,
        changes: file.changes,
        additions: file.additions,
        deletions: file.deletions,
        patch: file.patch
      }))
    });
  } catch (error) {
    console.error('GitHub compare error:', error);
    res.status(500).json({ error: 'Failed to compare commits' });
  }
});

export default router;
EOF

# 3. Исправляем server.ts - убираем несуществующий prisma импорт
cat > src/server.ts << 'EOF'
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import compression from 'compression';
import { createServer } from 'http';
import { Server } from 'socket.io';
import rateLimit from 'express-rate-limit';
import { PrismaClient } from '@prisma/client';

import authRoutes from './routes/auth';
import projectRoutes from './routes/projects';
import reviewRoutes from './routes/reviews';
import githubRoutes from './routes/github';

const app = express();
const server = createServer(app);
const io = new Server(server, {
  cors: {
    origin: process.env.FRONTEND_URL || "http://localhost:3000",
    methods: ["GET", "POST"]
  }
});

const prisma = new PrismaClient();
const PORT = process.env.PORT || 3001;

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});

// Middleware
app.use(helmet());
app.use(compression());
app.use(limiter);
app.use(cors({
  origin: process.env.FRONTEND_URL || "http://localhost:3000",
  credentials: true
}));
app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Middleware для добавления user в req (временно)
app.use((req: any, res, next) => {
  req.user = { id: 'temp-user-id' }; // TODO: Implement JWT auth
  next();
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/projects', projectRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/github', githubRoutes);

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    service: 'AI IT Solar Backend'
  });
});

// API info endpoint
app.get('/api', (req, res) => {
  res.json({
    service: 'AI IT Solar API',
    version: '1.0.0',
    endpoints: {
      auth: '/api/auth/*',
      projects: '/api/projects/*',
      reviews: '/api/reviews/*',
      github: '/api/github/*'
    }
  });
});

// WebSocket handling
io.on('connection', (socket) => {
  console.log('User connected:', socket.id);
  
  socket.on('join-review', (reviewId) => {
    socket.join(`review-${reviewId}`);
    socket.to(`review-${reviewId}`).emit('user-joined', socket.id);
  });
  
  socket.on('leave-review', (reviewId) => {
    socket.leave(`review-${reviewId}`);
    socket.to(`review-${reviewId}`).emit('user-left', socket.id);
  });
  
  socket.on('add-comment', (data) => {
    socket.to(`review-${data.reviewId}`).emit('new-comment', data);
  });
  
  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
  });
});

// Global error handler
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error(err.stack);
  res.status(500).json({ 
    error: 'Something went wrong!',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Internal server error'
  });
});

// Start server
server.listen(PORT, () => {
  console.log(`🚀 AI IT Solar Backend running on port ${PORT}`);
  console.log(`📡 WebSocket server ready`);
  console.log(`🌐 Environment: ${process.env.NODE_ENV}`);
  console.log(`📊 API endpoints available at http://localhost:${PORT}/api`);
});

export { app, io, prisma };
EOF

echo "✅ All fixes applied!"
echo ""
echo "🚀 Now restart the development server:"
echo "   Ctrl+C to stop current process"
echo "   npm run dev"
echo ""
echo "🌐 Frontend: http://localhost:3000"
echo "🔧 Backend: http://localhost:3001"
echo "📊 API Info: http://localhost:3001/api"