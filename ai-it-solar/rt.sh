# Переходим в корень проекта
cd /Users/asset/Documents/Pesochnica_AI_IT_SOLAR/ai-it-solar

# Тестируем все endpoints
echo "🧪 Testing Health Check:"
curl http://localhost:3001/health && echo ""

echo "🧪 Testing GitHub API:"
curl http://localhost:3001/api/github/status && echo ""

echo "🧪 Testing Projects (should return empty array):"
curl http://localhost:3001/api/projects && echo ""

echo "🧪 Testing Reviews (should return empty array):"
curl http://localhost:3001/api/reviews && echo ""

echo "🧪 Creating test project:"
curl -X POST http://localhost:3001/api/projects \
  -H "Content-Type: application/json" \
  -d '{"name": "Test Project", "description": "Local test", "language": "JavaScript"}' && echo ""

echo "🧪 Testing Projects again (should show new project):"
curl http://localhost:3001/api/projects && echo ""