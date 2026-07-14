import type { VercelRequest, VercelResponse } from '@vercel/node';
import { list } from '@vercel/blob';

function setCorsHeaders(res: VercelResponse) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
}

// Aggregates how many handwriting samples have been collected per letter by
// listing everything under tamil-letters/<slug>/ in Vercel Blob and counting
// pathnames per slug. No database required — the folder-per-letter layout
// created by /api/upload doubles as the source of truth for these counts.
export default async function handler(req: VercelRequest, res: VercelResponse) {
  setCorsHeaders(res);

  if (req.method === 'OPTIONS') {
    res.status(204).end();
    return;
  }

  if (req.method !== 'GET') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  try {
    const counts: Record<string, number> = {};
    let cursor: string | undefined;
    let total = 0;

    do {
      const result = await list({ prefix: 'tamil-letters/', cursor, limit: 1000 });
      for (const blob of result.blobs) {
        const parts = blob.pathname.split('/');
        // Expected shape: tamil-letters/<slug>/<uuid>.png
        if (parts.length < 3) continue;
        const slug = parts[1];
        counts[slug] = (counts[slug] ?? 0) + 1;
        total += 1;
      }
      cursor = result.cursor;
    } while (cursor);

    res.status(200).json({ total, counts });
  } catch (error) {
    console.error('Failed to compute stats from Vercel Blob', error);
    res.status(500).json({ error: 'Failed to load stats' });
  }
}
