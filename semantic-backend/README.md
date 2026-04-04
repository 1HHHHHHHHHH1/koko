---
title: VentureBridge Semantic Backend
emoji: "🧠"
colorFrom: blue
colorTo: indigo
sdk: docker
app_port: 7860
pinned: false
---

# VentureBridge Semantic Backend

Semantic matching backend that keeps the same `/predict` and `/predict/bulk`
API contract as the current ML backend.

## What it does

- Uses OpenAI embeddings for text meaning, not keyword-only matching
- Adds structured scoring for industry, stage, and funding range
- Lets the Flutter app switch engines by changing only one base URL

## Required environment variables

- `OPENAI_API_KEY`

## Optional environment variables

- `OPENAI_EMBED_MODEL` default: `text-embedding-3-large`
- `MATCH_THRESHOLD` default: `0.58`
- `SEMANTIC_WEIGHT` default: `0.84`
- `INDUSTRY_WEIGHT` default: `0.07`
- `STAGE_WEIGHT` default: `0.05`
- `FUNDING_WEIGHT` default: `0.04`
- `SEMANTIC_FLOOR` default: `0.60`
- `SEMANTIC_CEILING` default: `0.82`
- `INDUSTRY_MISMATCH_PENALTY` default: `0.09`
- `STAGE_MISMATCH_PENALTY` default: `0.06`
- `FUNDING_MISMATCH_PENALTY` default: `0.05`

## Local run

```bash
pip install -r requirements.txt
uvicorn main:app --reload
```

## Render deploy

This repo now includes a root-level `render.yaml` that deploys this service
from the `semantic-backend` directory.

Steps:

1. Push the repository to GitHub.
2. In Render, create a new Blueprint and select this repository.
3. During the first setup, enter `OPENAI_API_KEY` when Render prompts for it.
4. Deploy the service.
5. Copy the generated `.onrender.com` URL.

## Hugging Face Spaces deploy

If Render asks for a payment card, you can deploy this backend as a Docker Space
instead.

Steps:

1. Create a new Space on Hugging Face.
2. Choose `Docker` as the SDK.
3. Upload the contents of this `semantic-backend` folder.
4. In the Space settings, add a Secret named `OPENAI_API_KEY`.
5. Wait for the build to finish, then open the generated `*.hf.space` URL.

Notes:

- Free `CPU Basic` hardware is available on Spaces.
- Free Spaces can go to sleep when idle.
- The backend contract remains the same, so Flutter still switches by changing
  one base URL.

## Switch from Flutter

Open `lib/core/constants/ml_backend_constants.dart` and change:

```dart
static const String activeBaseUrl = semanticBaseUrl;
```
