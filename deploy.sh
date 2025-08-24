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
