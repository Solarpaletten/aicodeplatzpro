#!/bin/bash

echo "🔄 Converting backend to pure JavaScript..."

# 1. Обновляем package.json для JS
cat > package.json << 'EOF'
{
  "name": "ai-solar-backend",
  "version": "1.0.0",
  "description": "AI IT Solar Backend API - JavaScript Edition",
  "main": "src/server.js",
  "type": "module",
  "scripts": {
    "dev": "nodemon src/server.js",
    "start": "node src/server.js",
    "start:prod": "NODE_ENV=production node src/server.js",
    "prisma:generate": "prisma generate",
    "prisma:migrate": "prisma migrate dev",
    "prisma:deploy": "prisma migrate deploy",
    "prisma:studio": "prisma studio",
    "db:seed": "node prisma/seed.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "helmet": "^7.0.0",
    "morgan": "^1.10.0",
    "jsonwebtoken": "^9.0.0",
    "bcryptjs": "^2.4.3",
    "prisma": "^5.0.0",
    "@prisma/client": "^5.0.0",
    "socket.io": "^4.7.1",
    "multer": "^1.4.5-lts.1",
    "zod": "^3.21.4",
    "express-rate-limit": "^6.8.1",
    "compression": "^1.7.4",
    "dotenv": "^16.3.1"
  },
  "devDependencies": {
    "nodemon": "^2.0.22"
  },
  "engines": {
    "node": ">=18.0.0",
    "npm": ">=9.0.0"
  }
}
EOF

# 2. Создаем главный server.js
cat > src/server.js << 'EOF'
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import compression from 'compression';
import rateLimit from 'express-rate-limit';
import { PrismaClient } from '@prisma/client';
import dotenv from 'dotenv';

// Routes
import authRoutes from './routes/auth.js';
import projectRoutes from './routes/projects.js';
import reviewRoutes from './routes/reviews.js';
import githubRoutes from './routes/github.js';

dotenv.config();

const app = express();
const prisma = new PrismaClient();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(helmet());
app.use(compression());
app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:3000',
  credentials: true
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 минут
  max: 100 // максимум 100 запросов с одного IP
});
app.use('/api', limiter);

app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    service: 'AI IT Solar Backend',
    version: '1.0.0'
  });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/projects', projectRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/github', githubRoutes);

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, shutting down gracefully');
  await prisma.$disconnect();
  process.exit(0);
});

app.listen(PORT, () => {
  console.log(`🚀 AI IT Solar Backend running on port ${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
});

export { prisma };
EOF

# 3. Создаем routes/auth.js
cat > src/routes/auth.js << 'EOF'
import express from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { z } from 'zod';
import { prisma } from '../server.js';

const router = express.Router();

const registerSchema = z.object({
  email: z.string().email(),
  username: z.string().min(3),
  password: z.string().min(6),
  name: z.string().optional()
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string()
});

// POST /api/auth/register
router.post('/register', async (req, res) => {
  try {
    const data = registerSchema.parse(req.body);
    
    // Проверяем существование пользователя
    const existingUser = await prisma.user.findFirst({
      where: {
        OR: [
          { email: data.email },
          { username: data.username }
        ]
      }
    });
    
    if (existingUser) {
      return res.status(400).json({ error: 'User already exists' });
    }
    
    // Хешируем пароль
    const hashedPassword = await bcrypt.hash(data.password, 12);
    
    // Создаем пользователя
    const user = await prisma.user.create({
      data: {
        email: data.email,
        username: data.username,
        name: data.name,
        password: hashedPassword
      },
      select: {
        id: true,
        email: true,
        username: true,
        name: true,
        avatar: true
      }
    });
    
    // Создаем JWT токен
    const token = jwt.sign(
      { userId: user.id },
      process.env.JWT_SECRET || 'fallback-secret',
      { expiresIn: '7d' }
    );
    
    res.status(201).json({ user, token });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(400).json({ error: 'Registration failed' });
  }
});

// POST /api/auth/login
router.post('/login', async (req, res) => {
  try {
    const data = loginSchema.parse(req.body);
    
    // Находим пользователя
    const user = await prisma.user.findUnique({
      where: { email: data.email }
    });
    
    if (!user || !user.password) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    
    // Проверяем пароль
    const isValidPassword = await bcrypt.compare(data.password, user.password);
    
    if (!isValidPassword) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    
    // Создаем JWT токен
    const token = jwt.sign(
      { userId: user.id },
      process.env.JWT_SECRET || 'fallback-secret',
      { expiresIn: '7d' }
    );
    
    // Возвращаем данные без пароля
    const { password, ...userWithoutPassword } = user;
    
    res.json({ user: userWithoutPassword, token });
  } catch (error) {
    console.error('Login error:', error);
    res.status(400).json({ error: 'Login failed' });
  }
});

export default router;
EOF

# 4. Создаем routes/projects.js
cat > src/routes/projects.js << 'EOF'
import express from 'express';
import { z } from 'zod';
import { prisma } from '../server.js';

const router = express.Router();

const createProjectSchema = z.object({
  name: z.string().min(1),
  description: z.string().optional(),
  githubUrl: z.string().url().optional(),
  language: z.string().optional(),
  isPrivate: z.boolean().default(false)
});

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
    const data = createProjectSchema.parse(req.body);
    
    const project = await prisma.project.create({
      data: {
        ...data,
        userId: req.user?.id || 'default-user-id'
      },
      include: {
        user: { select: { id: true, username: true, name: true } }
      }
    });
    
    res.status(201).json(project);
  } catch (error) {
    res.status(400).json({ error: 'Failed to create project' });
  }
});

// GET /api/projects/:id
router.get('/:id', async (req, res) => {
  try {
    const project = await prisma.project.findUnique({
      where: { id: req.params.id },
      include: {
        user: { select: { id: true, username: true, name: true } },
        reviews: {
          include: {
            user: { select: { id: true, username: true, name: true } }
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

# 5. Создаем routes/reviews.js
cat > src/routes/reviews.js << 'EOF'
import express from 'express';
import { z } from 'zod';
import { prisma } from '../server.js';

const router = express.Router();

const createReviewSchema = z.object({
  title: z.string().min(1),
  description: z.string().optional(),
  oldCode: z.string(),
  newCode: z.string(),
  language: z.string(),
  projectId: z.string()
});

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
    const data = createReviewSchema.parse(req.body);
    
    const review = await prisma.review.create({
      data: {
        title: data.title,
        description: data.description,
        oldCode: data.oldCode,
        newCode: data.newCode,
        language: data.language,
        projectId: data.projectId,
        userId: req.user?.id || 'default-user-id',
        status: 'PENDING',
        riskLevel: 'LOW'
      },
      include: {
        user: { select: { id: true, username: true, name: true } },
        project: { select: { id: true, name: true } }
      }
    });
    
    res.status(201).json(review);
  } catch (error) {
    res.status(400).json({ error: 'Failed to create review' });
  }
});

// GET /api/reviews/:id
router.get('/:id', async (req, res) => {
  try {
    const review = await prisma.review.findUnique({
      where: { id: req.params.id },
      include: {
        user: { select: { id: true, username: true, name: true } },
        project: { select: { id: true, name: true } },
        comments: {
          include: { user: { select: { id: true, username: true, name: true } } },
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

# 6. Создаем routes/github.js
cat > src/routes/github.js << 'EOF'
import express from 'express';

const router = express.Router();

// GET /api/github/status
router.get('/status', (req, res) => {
  res.json({ 
    status: 'GitHub integration ready',
    features: ['webhooks', 'pr-analysis', 'repo-sync']
  });
});

export default router;
EOF

# 7. Удаляем TypeScript файлы и конфиги
rm -rf src/types/
rm -f tsconfig.json

echo "✅ Backend converted to pure JavaScript!"
echo "🚀 Ready to deploy with JS-only stack!"