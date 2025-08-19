# Создаем корневой package.json для workspace
cat > package.json << 'EOF'
{
  "name": "ai-it-solar-pro",
  "version": "1.0.0",
  "description": "AI-powered code review platform",
  "private": true,
  "workspaces": ["frontend", "backend"],
  "scripts": {
    "install:all": "npm install && cd backend && npm install && cd ../frontend && npm install",
    "build:backend": "cd backend && echo 'Backend JS ready - no build needed'",
    "build:frontend": "cd frontend && npm run build",
    "build": "npm run build:backend && npm run build:frontend",
    "dev:backend": "cd backend && npm run dev",
    "dev:frontend": "cd frontend && npm run dev",
    "start:backend": "cd backend && npm run start",
    "start:frontend": "cd frontend && npm run start"
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

# Проверяем структуру
echo "📁 Project structure:"
echo "Root:"
ls -la | grep -E "(package\.json|frontend|backend|render\.yaml)"

echo "Frontend:"
ls -la frontend/

echo "Backend:"
ls -la backend/ | grep -E "(package\.json|src)"

# Теперь деплоим
echo "🚀 Ready to deploy!"
./deploy.sh