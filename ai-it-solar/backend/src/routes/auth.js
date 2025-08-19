import express from 'express';

const router = express.Router();

// POST /api/auth/register
router.post('/register', async (req, res) => {
  try {
    res.status(201).json({ 
      user: { id: 'demo-1', username: 'demo', email: 'demo@example.com' },
      token: 'demo-token' 
    });
  } catch (error) {
    res.status(400).json({ error: 'Registration failed' });
  }
});

// POST /api/auth/login
router.post('/login', async (req, res) => {
  try {
    res.json({ 
      user: { id: 'demo-1', username: 'demo', email: 'demo@example.com' },
      token: 'demo-token' 
    });
  } catch (error) {
    res.status(400).json({ error: 'Login failed' });
  }
});

export default router;
