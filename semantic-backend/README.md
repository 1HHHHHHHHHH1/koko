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
- `SEMANTIC_WEIGHT` default: `0.78`
- `INDUSTRY_WEIGHT` default: `0.10`
- `STAGE_WEIGHT` default: `0.06`
- `FUNDING_WEIGHT` default: `0.06`

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

## Switch from Flutter

Open `lib/core/constants/ml_backend_constants.dart` and change:

```dart
static const String activeBaseUrl = semanticBaseUrl;
```
