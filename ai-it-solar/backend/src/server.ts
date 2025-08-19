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
