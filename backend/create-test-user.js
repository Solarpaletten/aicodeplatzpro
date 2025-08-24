import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function createTestUser() {
  try {
    // Создаем тестового пользователя
    const user = await prisma.user.create({
      data: {
        id: 'default-user-id',
        email: 'test@example.com',
        username: 'testuser',
        name: 'Test User'
      }
    });
    console.log('✅ Test user created:', user);
  } catch (error) {
    if (error.code === 'P2002') {
      console.log('✅ Test user already exists');
    } else {
      console.error('Error creating user:', error);
    }
  } finally {
    await prisma.$disconnect();
  }
}

createTestUser();
