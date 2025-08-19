#!/bin/bash

echo "🚀 AI IT Solar - Quick Setup Script"
echo "=================================="

# Install dependencies
echo "📦 Installing dependencies..."
npm run install:all

# Setup environment files
echo "🔧 Setting up environment files..."
cp backend/.env.example backend/.env
echo "⚠️  Don't forget to update backend/.env with your actual API keys!"

# Setup database
echo "🗄️ Setting up database..."
cd backend
npx prisma generate
echo "⚠️  Run 'npm run prisma:migrate' when your database is ready!"

cd ..

echo "✅ Setup complete!"
echo ""
echo "🚀 To start development:"
echo "   npm run dev"
echo ""
echo "📚 To setup database:"
echo "   cd backend && npm run prisma:migrate"
echo ""
echo "🌐 Frontend will be available at: http://localhost:3000"
echo "🔧 Backend will be available at: http://localhost:3001"
