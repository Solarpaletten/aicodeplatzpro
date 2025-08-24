# Проверим где находится aicoderplatz проект
find /var/www -name "*aicodeplatz*" -type d

# Запустим в PM2
cd /var/www/ai/aicodeplatzpro/ai-it-solar/backend/
pm2 start src/server.js --name "aicoderplatz-api"

# Проверим PM2
pm2 list