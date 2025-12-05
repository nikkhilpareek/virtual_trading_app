// aiService.js — Groq FREE version
// Uses Groq Llama 3.1 70B for fast & free AI summarization.

const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });
const axios = require('axios');

const GROQ_API_KEY = process.env.GROQ_API_KEY;
const GROQ_MODEL = process.env.GROQ_MODEL || 'llama-3.1-70b-versatile';

if (!GROQ_API_KEY) {
  console.error('❌ GROQ_API_KEY missing in .env');
}

const GROQ_API_URL = 'https://api.groq.com/openai/v1/chat/completions';

// Build system prompt
function buildSystemPrompt() {
  return `
You summarize market news into very short, simple 1–2 line bullet points.
Rules:
- Use simple ans easy English that indians can understand
- Each summary must mention the stock/crypto clearly
- Keep it short, useful, and understandable
- No more than 2 sentences
- Output JSON exactly like: { "highlights": ["...", "..."] }
`;
}

// Build user input (list of articles)
function buildUserContent(articles, limit) {
  let text = `Summarize the following news into ${limit} short bullet points:\n\n`;

  articles.forEach((a, i) => {
    text += `News ${i + 1}:\n`;
    text += `Title: ${a.title}\n`;
    text += `Description: ${a.description}\n`;
    text += `Source: ${a.source}\n\n`;
  });

  text += `
Return EXACT JSON:
{
  "highlights": ["...", "..."]
}
  `;

  return text;
}

// Call the Groq Chat API
async function callGroq(messages) {
  if (!GROQ_API_KEY) throw new Error('GROQ_API_KEY missing');
  const payload = {
    model: GROQ_MODEL,
    messages,
    temperature: 0.5,
    max_tokens: 400,
  };

  try {
    const resp = await axios.post(GROQ_API_URL, payload, {
      headers: {
        Authorization: `Bearer ${GROQ_API_KEY}`,
        'Content-Type': 'application/json',
      },
      timeout: 15000,
      validateStatus: (s) => s >= 200 && s < 500, // surface 4xx body
    });

    if (resp.status >= 400) {
      const detail = typeof resp.data === 'object' ? JSON.stringify(resp.data) : String(resp.data);
      throw new Error(`Groq API ${resp.status}: ${detail}`);
    }
    return resp.data;
  } catch (err) {
    if (err.response) {
      const detail = typeof err.response.data === 'object' ? JSON.stringify(err.response.data) : String(err.response.data);
      throw new Error(`Groq request failed ${err.response.status}: ${detail}`);
    }
    throw err;
  }
}

// Main summarizer
async function summarizeHighlights(articles, limit = 5) {
  limit = Math.max(1, Math.min(10, limit));

  const system = { role: 'system', content: buildSystemPrompt() };
  const user = { role: 'user', content: buildUserContent(articles, limit) };

  const response = await callGroq([system, user]);
  let text = response?.choices?.[0]?.message?.content || '';

  // Extract JSON safely
  try {
    const start = text.indexOf('{');
    const jsonString = text.slice(start);
    const parsed = JSON.parse(jsonString);

    if (Array.isArray(parsed.highlights)) {
      return parsed.highlights.slice(0, limit);
    }
  } catch (e) {
    console.warn('⚠️ JSON parsing failed:', e.message);
  }

  // Fallback: split lines
  return text
    .split('\n')
    .filter((l) => l.trim().length > 0)
    .slice(0, limit)
    .map((l) => l.replace(/^\d+[\.\-\)]\s*/, '').trim());
}

module.exports = { summarizeHighlights };
