# Tamil Handwriting Collector

Collects handwriting samples for all 247 Tamil letters (உயிர் + மெய் +
உயிர்மெய் + ஆய்த எழுத்து) to improve a Tamil OCR handwriting model. Shows one
letter at a time, the user draws it, "Next" uploads the drawing and moves on.
Includes a stats dashboard showing samples collected per letter.

## Structure

- `flutter_app/` — Flutter web app (UI, canvas, letter cycling, dashboard)
- `api/upload.ts` — Vercel serverless function, stores drawings in Vercel Blob
- `api/stats.ts` — Vercel serverless function, aggregates counts per letter
- `vercel.json` — build config (installs the Flutter SDK during the Vercel build, since it isn't preinstalled)

## One-time Vercel setup

1. `vercel link` (or import the repo from the Vercel dashboard) to create the project.
2. In the Vercel dashboard: **Storage → Create Database → Blob**, and connect it
   to this project. This provisions `BLOB_READ_WRITE_TOKEN` automatically as a
   project env var — no manual token copying needed.
3. Deploy: `vercel --prod` (or push to the connected git branch).

## Local development

Flutter app only (no uploads, good for UI work):
```bash
cd flutter_app
flutter run -d chrome
```

Full stack against a deployed backend (uploads work, since Blob needs real credentials):
```bash
cd flutter_app
flutter run -d chrome --dart-define=API_BASE_URL=https://<your-vercel-deployment>.vercel.app
```

## Verifying a deploy

1. Open the deployed URL, draw something, hit **Next** — should advance to a
   new letter with no error SnackBar.
2. Open the bar-chart icon (top right) — the dashboard should show the letter
   you just drew with a count of at least 1.
3. In the Vercel dashboard under Storage → your Blob store, confirm a PNG
   exists under `tamil-letters/<slug>/`.

## Notes / known limitations

- The upload endpoint is intentionally open (no auth) for easy data
  collection — fine for a low-traffic internal tool, revisit before sharing
  the link widely.
- Letter order is a shuffled queue per session (no repeats until all 247 have
  appeared), not pure random — this maximizes coverage per session while
  still feeling random to the user.
- Feeding collected images into actual OCR model retraining is a separate,
  unbuilt step.
