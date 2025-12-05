// newsService.js
// Fetches stock and crypto news and returns a combined array of simplified articles
const axios = require('axios');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });

const FINNHUB_API_KEY = process.env.FINNHUB_API_KEY;
const CRYPTOCOMPARE_API_KEY = process.env.CRYPTOCOMPARE_API_KEY;

// Simple in-memory cache to reduce API calls
let cache = null;
let cacheTime = 0;
const CACHE_TTL = parseInt(process.env.CACHE_TTL || '300', 10); // seconds

async function fetchFromFinnhub() {
  if (!FINNHUB_API_KEY) return [];

  try {
    const url = `https://finnhub.io/api/v1/news?category=general&token=${FINNHUB_API_KEY}`;
    const resp = await axios.get(url, { timeout: 12000 });
    return (resp.data || []).slice(0, 8).map((a) => ({
      title: a.headline || a.title || '',
      description: a.summary || '',
      url: a.url,
      source: a.source || 'finnhub',
      publishedAt: a.datetime ? new Date(a.datetime * 1000).toISOString() : undefined,
    }));
  } catch (err) {
    console.warn('Finnhub fetch error', err.message);
    return [];
  }
}

async function fetchFromCryptoCompare() {
  if (!CRYPTOCOMPARE_API_KEY) return [];

  try {
    const url = `https://min-api.cryptocompare.com/data/v2/news/?lang=EN`;
    const resp = await axios.get(url, {
      timeout: 12000,
      headers: {
        // CryptoCompare expects an Authorization header with Apikey
        authorization: `Apikey ${CRYPTOCOMPARE_API_KEY}`,
        Apikey: CRYPTOCOMPARE_API_KEY,
      },
      params: { api_key: CRYPTOCOMPARE_API_KEY },
    });
    return (resp.data.Data || []).slice(0, 8).map((a) => ({
      title: a.title || '',
      description: a.body || a.body_excerpt || '',
      url: a.url,
      source: a.source || 'cryptocompare',
      publishedAt: a.published_on ? new Date(a.published_on * 1000).toISOString() : undefined,
    }));
  } catch (err) {
    console.warn('CryptoCompare fetch error', err.message);
    return [];
  }
}

async function getCombinedNews() {
  const now = Date.now();
  if (cache && (now - cacheTime) / 1000 < CACHE_TTL) {
    return cache;
  }

  const [stockNews, cryptoNews] = await Promise.allSettled([
    fetchFromFinnhub(),
    fetchFromCryptoCompare(),
  ]);

  const articles = [];
  if (stockNews.status === 'fulfilled') articles.push(...stockNews.value);
  if (cryptoNews.status === 'fulfilled') articles.push(...cryptoNews.value);

  const sorted = articles
    .filter((a) => a.title || a.description)
    .sort((a, b) => {
      const ta = a.publishedAt ? new Date(a.publishedAt).getTime() : 0;
      const tb = b.publishedAt ? new Date(b.publishedAt).getTime() : 0;
      return tb - ta;
    })
    .slice(0, 12);

  cache = sorted;
  cacheTime = now;
  return sorted;
}

module.exports = { getCombinedNews };
// Extra debug helper to test sources individually
async function getNewsDebug() {
  const finnhubHasKey = !!FINNHUB_API_KEY;
  const cryptoCompareHasKey = !!CRYPTOCOMPARE_API_KEY;
  let finnhubCount = 0;
  let cryptoCompareCount = 0;
  try { finnhubCount = (await fetchFromFinnhub()).length; } catch (_) {}
  try { cryptoCompareCount = (await fetchFromCryptoCompare()).length; } catch (_) {}
  return { finnhubHasKey, cryptoCompareHasKey, finnhubCount, cryptoCompareCount };
}

module.exports.getNewsDebug = getNewsDebug;
