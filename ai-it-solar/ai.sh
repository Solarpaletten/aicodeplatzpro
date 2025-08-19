echo "🧪 Testing improved project creation:"
curl -X POST http://localhost:3001/api/projects \
  -H "Content-Type: application/json" \
  -d '{"name": "Amazing Project", "description": "This should work now!", "language": "JavaScript"}' && echo ""

echo "🧪 Checking if project was created:"
curl http://localhost:3001/api/projects && echo ""

echo "🧪 Creating another project:"
curl -X POST http://localhost:3001/api/projects \
  -H "Content-Type: application/json" \
  -d '{"name": "Second Project", "language": "TypeScript"}' && echo ""

echo "🧪 Final check - all projects:"
curl http://localhost:3001/api/projects && echo ""