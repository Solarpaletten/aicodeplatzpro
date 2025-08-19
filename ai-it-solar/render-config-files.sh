#!/bin/bash

echo "🚀 Preparing AI IT Solar PRO for Render deployment..."

# 1. Создаем оптимизированный render.yaml
cat > render.yaml << 'EOF'
services:
  # Backend API Service
  - type: web
    name: aicodeplatzpro-backend
    env: node
    plan: starter
    buildCommand: cd backend && npm install && npm run build
    startCommand: cd backend && npm run start:prod
    healthCheckPath: /health
    envVars:
      - key: NODE_ENV
        value: production
      - key: DATABASE_URL
        fromDatabase:
          name: aicodeplatzpro-db
          property: connectionString
      - key: JWT_SECRET
        generateValue: true
      - key: FRONTEND_URL
        value: https://aicodeplatzpro.onrender.com
      - key: PORT
        value: 10000

  # Frontend Static Site
  - type: web
    name: aicodeplatzpro-frontend
    env: static
    buildCommand: cd frontend && npm install && npm run build
    staticPublishPath: frontend/dist
    envVars:
      - key: VITE_API_URL
        value: https://aicodeplatzpro-backend.onrender.com/api

# Database
databases:
  - name: aicodeplatzpro-db
    databaseName: ai_solar_production
    user: ai_solar_user
    plan: starter
EOF

# 2. Обновляем backend package.json для production
cd backend

# Добавляем serve для production
npm install --save serve

# Создаем production-ready package.json
cat > package.json << 'EOF'
{
  "name": "ai-solar-backend",
  "version": "1.0.0",
  "description": "AI IT Solar Backend API",
  "main": "dist/server.js",
  "scripts": {
    "dev": "nodemon src/server.ts",
    "build": "tsc && npx prisma generate",
    "start": "node dist/server.js",
    "start:prod": "NODE_ENV=production node dist/server.js",
    "postbuild": "npx prisma migrate deploy",
    "prisma:generate": "prisma generate",
    "prisma:migrate": "prisma migrate dev",
    "prisma:deploy": "prisma migrate deploy",
    "prisma:studio": "prisma studio",
    "db:seed": "ts-node prisma/seed.ts",
    "test": "jest",
    "lint": "eslint src/**/*.ts"
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
    "openai": "^3.3.0",
    "@octokit/rest": "^20.0.1",
    "zod": "^3.21.4",
    "express-rate-limit": "^6.8.1",
    "compression": "^1.7.4",
    "serve": "^14.2.0"
  },
  "devDependencies": {
    "typescript": "^5.1.3",
    "nodemon": "^2.0.22",
    "ts-node": "^10.9.1",
    "@types/express": "^4.17.17",
    "@types/node": "^20.3.1",
    "@types/cors": "^2.8.13",
    "@types/bcryptjs": "^2.4.2",
    "@types/jsonwebtoken": "^9.0.2",
    "@types/multer": "^1.4.7",
    "@types/morgan": "^1.9.4",
    "@types/compression": "^1.7.2",
    "eslint": "^8.42.0",
    "@typescript-eslint/eslint-plugin": "^5.59.11",
    "@typescript-eslint/parser": "^5.59.11",
    "jest": "^29.5.0",
    "@types/jest": "^29.5.2"
  },
  "engines": {
    "node": ">=18.0.0",
    "npm": ">=9.0.0"
  }
}
EOF

# 3. Обновляем frontend package.json
cd ../frontend

cat > package.json << 'EOF'
{
  "name": "ai-solar-frontend",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "typescript": "^4.9.5",
    "react-router-dom": "^6.11.2",
    "react-query": "^3.39.3",
    "@tanstack/react-query": "^4.29.7",
    "axios": "^1.4.0",
    "socket.io-client": "^4.7.1",
    "@monaco-editor/react": "^4.5.1",
    "framer-motion": "^10.12.16",
    "react-hot-toast": "^2.4.1",
    "react-hook-form": "^7.44.3",
    "@hookform/resolvers": "^3.1.1",
    "zod": "^3.21.4",
    "zustand": "^4.3.8",
    "lucide-react": "^0.258.0",
    "clsx": "^1.2.1",
    "tailwind-merge": "^1.13.2",
    "serve": "^14.2.0"
  },
  "devDependencies": {
    "@types/react": "^18.2.6",
    "@types/react-dom": "^18.2.4",
    "@vitejs/plugin-react": "^4.0.0",
    "vite": "^4.3.9",
    "tailwindcss": "^3.3.2",
    "autoprefixer": "^10.4.14",
    "postcss": "^8.4.24",
    "@types/node": "^20.3.1",
    "eslint": "^8.42.0",
    "@typescript-eslint/eslint-plugin": "^5.59.11",
    "@typescript-eslint/parser": "^5.59.11",
    "prettier": "^2.8.8"
  },
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "start": "vite preview",
    "start:prod": "npx serve -s dist -l $PORT",
    "lint": "eslint . --ext ts,tsx --report-unused-disable-directives --max-warnings 0",
    "preview": "vite preview"
  },
  "engines": {
    "node": ">=18.0.0",
    "npm": ">=9.0.0"
  }
}
EOF

# 4. Создаем оптимизированный vite config для production
cat > vite.config.ts << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
  build: {
    outDir: 'dist',
    sourcemap: false,
    minify: 'terser',
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'],
          router: ['react-router-dom'],
          ui: ['lucide-react', 'framer-motion']
        }
      }
    }
  },
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: process.env.VITE_API_URL || 'http://localhost:3001',
        changeOrigin: true,
      },
    },
  },
})
EOF

# 5. Обновляем корневой package.json
cd ..

cat > package.json << 'EOF'
{
  "name": "ai-it-solar-pro",
  "version": "1.0.0",
  "description": "AI-powered code review platform - Professional Edition",
  "private": true,
  "workspaces": [
    "frontend",
    "backend"
  ],
  "scripts": {
    "dev": "concurrently \"npm run dev:backend\" \"npm run dev:frontend\"",
    "dev:frontend": "cd frontend && npm run dev",
    "dev:backend": "cd backend && npm run dev",
    "build": "npm run build:backend && npm run build:frontend",
    "build:backend": "cd backend && npm run build",
    "build:frontend": "cd frontend && npm run build",
    "start": "concurrently \"npm run start:backend\" \"npm run start:frontend\"",
    "start:backend": "cd backend && npm run start:prod",
    "start:frontend": "cd frontend && npm run start:prod",
    "install:all": "npm install && cd backend && npm install && cd ../frontend && npm install",
    "clean": "rm -rf node_modules backend/node_modules frontend/node_modules backend/dist frontend/dist",
    "setup:db": "cd backend && npm run prisma:deploy && npm run db:seed",
    "docker:up": "docker-compose up -d",
    "docker:down": "docker-compose down",
    "deploy:render": "git push origin main && echo 'Deployed to Render!'"
  },
  "devDependencies": {
    "concurrently": "^8.2.0"
  },
  "engines": {
    "node": ">=18.0.0",
    "npm": ">=9.0.0"
  },
  "repository": {
    "type": "git",
    "url": "https://github.com/Solarpaletten/aicodeplatzpro.git"
  },
  "author": "AI IT Solar Team",
  "license": "MIT"
}
EOF

# 6. Обновляем .gitignore для production
cat > .gitignore << 'EOF'
# Dependencies
node_modules/
*/node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Environment variables
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Database
prisma/migrations/dev/
*.db
*.sqlite

# Build outputs
dist/
build/
*.tsbuildinfo

# Logs
logs
*.log

# Runtime data
pids
*.pid
*.seed
*.pid.lock

# Coverage directory
coverage/

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Temporary files
tmp/
temp/

# Render specific
.render/

# Production files to keep
!render.yaml
EOF

# 7. Создаем deployment script
cat > deploy.sh << 'EOF'
#!/bin/bash

echo "🚀 Deploying AI IT Solar PRO to Render..."

# 1. Проверяем готовность к деплою
echo "🔍 Checking deployment readiness..."

if [ ! -f "render.yaml" ]; then
    echo "❌ render.yaml not found!"
    exit 1
fi

if [ ! -f "backend/package.json" ]; then
    echo "❌ Backend package.json not found!"
    exit 1
fi

if [ ! -f "frontend/package.json" ]; then
    echo "❌ Frontend package.json not found!"
    exit 1
fi

# 2. Проверяем зависимости
echo "📦 Installing dependencies..."
npm run install:all

# 3. Тестируем сборку
echo "🔨 Testing build process..."
npm run build

if [ $? -ne 0 ]; then
    echo "❌ Build failed! Fix errors before deployment."
    exit 1
fi

# 4. Коммитим и пушим
echo "📤 Committing and pushing to GitHub..."

git add .
git commit -m "🚀 Production Deploy: AI IT Solar PRO

✨ Ready for Render deployment:
- Backend: Node.js + Express + Prisma
- Frontend: React + TypeScript + Tailwind  
- Database: PostgreSQL production config
- Optimized build settings
- Health checks enabled

🎯 Deploy URLs:
- Frontend: https://aicodeplatzpro.onrender.com
- Backend: https://aicodeplatzpro-backend.onrender.com

⚡ Auto-deploy enabled on main branch push"

git push origin main

echo ""
echo "✅ Deployment initiated!"
echo ""
echo "🎯 Next steps:"
echo "1. Go to https://dashboard.render.com"
echo "2. Connect your GitHub repo: Solarpaletten/aicodeplatzpro"
echo "3. Render will auto-detect render.yaml and create services"
echo "4. Wait ~5-10 minutes for deployment"
echo ""
echo "🌐 Your app will be live at:"
echo "   https://aicodeplatzpro.onrender.com"
echo ""
echo "🚀 AI IT Solar PRO - From code to production in minutes!"
EOF

chmod +x deploy.sh

echo ""
echo "✅ Render deployment files prepared!"
echo ""
echo "📁 Created files:"
echo "   ├── render.yaml          (Render service configuration)"
echo "   ├── backend/package.json (Optimized for production)"
echo "   ├── frontend/package.json (With build optimizations)"
echo "   ├── frontend/vite.config.ts (Production build config)"
echo "   ├── .gitignore           (Production-ready)"
echo "   └── deploy.sh            (One-click deployment)"
echo ""
echo "🚀 Ready to deploy! Run:"
echo "   ./deploy.sh"
echo ""
echo "🎯 This will:"
echo "   ✅ Test build process"
echo "   ✅ Commit all changes"
echo "   ✅ Push to GitHub"
echo "   ✅ Trigger Render auto-deploy"