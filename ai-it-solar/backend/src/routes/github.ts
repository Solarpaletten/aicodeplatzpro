import { Router } from 'express';
import { Octokit } from '@octokit/rest';

const router = Router();

// Инициализация GitHub API клиента
const getOctokit = (token?: string) => {
  return new Octokit({
    auth: token || process.env.GITHUB_TOKEN,
  });
};

// GET /api/github/repos - Репозитории пользователя
router.get('/repos', async (req, res) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({ error: 'GitHub token required' });
    }
    
    const octokit = getOctokit(token);
    const { data: repos } = await octokit.rest.repos.listForAuthenticatedUser({
      sort: 'updated',
      per_page: 50
    });
    
    const formattedRepos = repos.map(repo => ({
      id: repo.id,
      name: repo.name,
      fullName: repo.full_name,
      description: repo.description,
      language: repo.language,
      private: repo.private,
      htmlUrl: repo.html_url,
      updatedAt: repo.updated_at
    }));
    
    res.json(formattedRepos);
  } catch (error) {
    console.error('GitHub repos error:', error);
    res.status(500).json({ error: 'Failed to fetch repositories' });
  }
});

// GET /api/github/commits/:owner/:repo - Коммиты репозитория
router.get('/commits/:owner/:repo', async (req, res) => {
  try {
    const { owner, repo } = req.params;
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    const octokit = getOctokit(token);
    const { data: commits } = await octokit.rest.repos.listCommits({
      owner,
      repo,
      per_page: 20
    });
    
    const formattedCommits = commits.map(commit => ({
      sha: commit.sha,
      message: commit.commit.message,
      author: commit.commit.author,
      date: commit.commit.author?.date,
      htmlUrl: commit.html_url
    }));
    
    res.json(formattedCommits);
  } catch (error) {
    console.error('GitHub commits error:', error);
    res.status(500).json({ error: 'Failed to fetch commits' });
  }
});

// POST /api/github/compare - Сравнение коммитов
router.post('/compare', async (req, res) => {
  try {
    const { owner, repo, base, head } = req.body;
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    const octokit = getOctokit(token);
    const { data: comparison } = await octokit.rest.repos.compareCommits({
      owner,
      repo,
      base,
      head
    });
    
    res.json({
      status: comparison.status,
      ahead_by: comparison.ahead_by,
      behind_by: comparison.behind_by,
      total_commits: comparison.total_commits,
      files: comparison.files?.map(file => ({
        filename: file.filename,
        status: file.status,
        changes: file.changes,
        additions: file.additions,
        deletions: file.deletions,
        patch: file.patch
      }))
    });
  } catch (error) {
    console.error('GitHub compare error:', error);
    res.status(500).json({ error: 'Failed to compare commits' });
  }
});

export default router;
