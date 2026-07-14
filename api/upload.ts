import type { VercelRequest, VercelResponse } from '@vercel/node';
import { put } from '@vercel/blob';
import { randomUUID } from 'crypto';

// Only hex-codepoint slugs (as produced by slugForLetter() in the Flutter
// app) are accepted as storage keys, to rule out path traversal / arbitrary
// blob-key injection from the request body.
const SLUG_PATTERN = /^[0-9A-F]{4,6}(-[0-9A-F]{4,6})*$/;

// A single handwriting PNG shouldn't exceed a few hundred KB; reject
// anything wildly oversized before decoding it.
const MAX_IMAGE_BASE64_LENGTH = 5_000_000; // ~3.5MB decoded

function setCorsHeaders(res: VercelResponse) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  setCorsHeaders(res);

  if (req.method === 'OPTIONS') {
    res.status(204).end();
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  const { letterSlug, letterDisplay, imageBase64 } = req.body ?? {};

  if (typeof letterSlug !== 'string' || !SLUG_PATTERN.test(letterSlug)) {
    res.status(400).json({ error: 'Invalid letterSlug' });
    return;
  }

  if (typeof imageBase64 !== 'string' || imageBase64.length === 0) {
    res.status(400).json({ error: 'Missing imageBase64' });
    return;
  }

  if (imageBase64.length > MAX_IMAGE_BASE64_LENGTH) {
    res.status(413).json({ error: 'Image too large' });
    return;
  }

  let imageBuffer: Buffer;
  try {
    imageBuffer = Buffer.from(imageBase64, 'base64');
  } catch {
    res.status(400).json({ error: 'imageBase64 is not valid base64' });
    return;
  }

  try {
    const blob = await put(
      `tamil-letters/${letterSlug}/${randomUUID()}.png`,
      imageBuffer,
      {
        access: 'public',
        contentType: 'image/png',
      },
    );

    res.status(200).json({
      success: true,
      url: blob.url,
      letterDisplay: typeof letterDisplay === 'string' ? letterDisplay : undefined,
    });
  } catch (error) {
    console.error('Failed to upload to Vercel Blob', error);
    res.status(500).json({ error: 'Upload failed' });
  }
}
