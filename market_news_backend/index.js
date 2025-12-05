// index.js - Express server
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });
const express = require('express');
const app = express();
const newsService = require('./newsService');
const aiService = require('./aiService');

let PORT = Number(process.env.PORT || 8080);

app.use(express.json());

app.get('/health', (_req, res) => res.json({ ok: true }));

// Friendly root route to help when opening http://localhost:<port>/
app.get('/', (_req, res) => {
  res.json({
    ok: true,
    message: 'Market News Backend running',
    endpoints: ['/health', '/market-news', '/market-news?limit=5', '/market-news/debug'],
  });
});

// Log safe env presence on startup (no secrets printed)
console.log('[env] GROQ key:', !!process.env.GROQ_API_KEY, 'model:', process.env.GROQ_MODEL || '(default)');
console.log('[env] Finnhub key:', !!process.env.FINNHUB_API_KEY, 'CryptoCompare key:', !!process.env.CRYPTOCOMPARE_API_KEY);

// Debug endpoint to verify sources and counts
app.get('/market-news/debug', async (_req, res) => {
  try {
    const dbg = await newsService.getNewsDebug();
    res.json({ ok: true, ...dbg });
  } catch (e) {
    res.status(500).json({ ok: false, error: e.message });
  }
});

// Quick AI status endpoint to surface Groq errors without 500s
app.get('/market-news/ai-status', async (_req, res) => {
  try {
    if (!process.env.GROQ_API_KEY) {
      return res.json({ ok: false, ai: 'disabled', reason: 'GROQ_API_KEY not set' });
    }
    const sampleArticles = [
      { title: 'Bitcoin rises 2%', description: 'BTC gains amid positive risk sentiment', source: 'sample' },
      { title: 'Apple beats earnings', description: 'AAPL posts strong quarter on iPhone demand', source: 'sample' },
    ];
    const highlights = await aiService.summarizeHighlights(sampleArticles, 2);
    return res.json({ ok: true, ai: 'groq', highlights });
  } catch (e) {
    return res.json({ ok: false, ai: 'error', error: String(e.message || e) });
  }
});

// Single endpoint: GET /market-news
app.get('/market-news', async (req, res) => {
  try {
    const limit = parseInt(req.query.limit || '5', 10);
    const articles = await newsService.getCombinedNews();

    if (!articles || articles.length === 0) {
      return res.status(502).json({ error: 'No news articles available' });
    }

    let highlights;
    const simpleFallback = () =>
      articles
        .slice(0, Math.max(1, Math.min(10, limit)))
        .map((a) => {
          const base = a.title || a.description || 'Market update';
          return base.length > 140 ? base.slice(0, 137) + '…' : base;
        });

    if (!process.env.GROQ_API_KEY) {
      highlights = simpleFallback();
      return res.json({ highlights, ai: 'disabled' });
    }

    try {
      highlights = await aiService.summarizeHighlights(articles, limit);
      return res.json({ highlights, ai: 'groq' });
    } catch (aiErr) {
      console.warn('AI summarize failed, falling back to titles:', aiErr?.message || aiErr);
      highlights = simpleFallback();
      return res.json({ highlights, ai: 'fallback' });
    }
  } catch (err) {
    console.error('Server error', err);
    return res.status(500).json({ error: 'Internal server error', details: err.message });
  }
});

function startServer(port, attemptsLeft = 5) {
  const server = app.listen(port, () => {
    console.log(`Market news backend listening on port ${port}`);
  });

  server.on('error', (err) => {
    if (err && err.code === 'EADDRINUSE' && attemptsLeft > 0) {
      const nextPort = port + 1;
      console.warn(`Port ${port} in use. Retrying on ${nextPort}...`);
      setTimeout(() => startServer(nextPort, attemptsLeft - 1), 300);
    } else {
      console.error('Failed to start server:', err.message || err);
      process.exit(1);
    }
  });
}

startServer(PORT);

module.exports = app;
