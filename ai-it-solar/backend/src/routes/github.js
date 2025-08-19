import express from 'express';

const router = express.Router();

// GET /api/github/status
router.get('/status', (req, res) => {
  res.json({ 
    status: 'GitHub integration ready',
    features: ['webhooks', 'pr-analysis', 'repo-sync']
  });
});

export default router;
