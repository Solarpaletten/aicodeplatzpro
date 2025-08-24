import express from 'express';
const router = express.Router();

const GITHUB_TOKEN = process.env.GITHUB_TOKEN || '';

const ghHeaders = {
  'Accept': 'application/vnd.github+json',
  ...(GITHUB_TOKEN ? { 'Authorization': `Bearer ${GITHUB_TOKEN}` } : {})
};

// GET /api/github/files?owner=&repo=&base=&head=
router.get('/files', async (req, res) => {
  try {
    const { owner, repo, base, head } = req.query;
    if (!owner || !repo || !base || !head) {
      return res.status(400).json({ error: 'owner, repo, base, head are required' });
    }
    const url = `https://api.github.com/repos/${owner}/${repo}/compare/${base}...${head}`;
    const r = await fetch(url, { headers: ghHeaders });
    if (!r.ok) return res.status(r.status).send(await r.text());
    const data = await r.json();
    const files = (data.files || []).map(f => ({
      filename: f.filename,
      status: f.status,            // modified / added / removed / renamed
      additions: f.additions,
      deletions: f.deletions
    }));
    res.json({ base: data.base_commit?.sha, head: head, files });
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});

// GET /api/github/file?owner=&repo=&ref=&path=
router.get('/file', async (req, res) => {
  try {
    const { owner, repo, ref, path } = req.query;
    if (!owner || !repo || !ref || !path) {
      return res.status(400).json({ error: 'owner, repo, ref, path are required' });
    }
    const raw = `https://raw.githubusercontent.com/${owner}/${repo}/${ref}/${path}`;
    const r = await fetch(raw, { headers: GITHUB_TOKEN ? { Authorization: `Bearer ${GITHUB_TOKEN}` } : {} });
    if (!r.ok) {
      if (r.status === 404) return res.type('text/plain').send(''); // удалён — сравниваем с пустым
      return res.status(r.status).send(await r.text());
    }
    res.type('text/plain').send(await r.text());
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});

export default router;
