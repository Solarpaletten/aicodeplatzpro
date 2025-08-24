# Сначала исправим remote URL
git remote set-url origin https://github.com/Solarpaletten/aicodeplatzpro.git

# Теперь пушим весь наш full-stack проект
git add .
git commit -m "🚀 AI IT Solar PRO - Full-Stack Version

✨ Features:
- Backend: Node.js + Express + Prisma + TypeScript
- Frontend: React + TypeScript + Tailwind + Vite  
- Database: PostgreSQL with complete schema
- Real-time: WebSocket support
- API: Complete CRUD endpoints
- Deploy: Ready for Render.com

📊 Structure:
- backend/ - API server with Prisma ORM
- frontend/ - React app with modern UI
- Docker + Render configs included

🎯 Ready for production deployment!"

git push origin main