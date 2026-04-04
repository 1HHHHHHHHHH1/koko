"""
Semantic matching backend for VentureBridge.

This service keeps the same /predict and /predict/bulk contract as the
existing ML backend so the Flutter app can switch engines by changing only
the base URL.
"""

from __future__ import annotations

import math
import os
from typing import Any, Iterable, List, Optional

import httpx
import numpy as np
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "").strip()
OPENAI_BASE_URL = os.getenv("OPENAI_BASE_URL", "https://api.openai.com/v1").rstrip("/")
EMBED_MODEL = os.getenv("OPENAI_EMBED_MODEL", "text-embedding-3-large").strip()
MATCH_THRESHOLD = float(os.getenv("MATCH_THRESHOLD", "0.58"))
SEMANTIC_WEIGHT = float(os.getenv("SEMANTIC_WEIGHT", "0.84"))
INDUSTRY_WEIGHT = float(os.getenv("INDUSTRY_WEIGHT", "0.07"))
STAGE_WEIGHT = float(os.getenv("STAGE_WEIGHT", "0.05"))
FUNDING_WEIGHT = float(os.getenv("FUNDING_WEIGHT", "0.04"))
SEMANTIC_FLOOR = float(os.getenv("SEMANTIC_FLOOR", "0.60"))
SEMANTIC_CEILING = float(os.getenv("SEMANTIC_CEILING", "0.82"))
INDUSTRY_MISMATCH_PENALTY = float(os.getenv("INDUSTRY_MISMATCH_PENALTY", "0.09"))
STAGE_MISMATCH_PENALTY = float(os.getenv("STAGE_MISMATCH_PENALTY", "0.06"))
FUNDING_MISMATCH_PENALTY = float(os.getenv("FUNDING_MISMATCH_PENALTY", "0.05"))
HTTP_TIMEOUT = float(os.getenv("HTTP_TIMEOUT_SECONDS", "30"))

app = FastAPI(title="VentureBridge Semantic Matching API", version="1.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


class PredictRequest(BaseModel):
    project_description: str
    project_category: str
    funding_goal: float
    project_title: Optional[str] = ""
    project_stage: Optional[str] = ""
    project_tags: List[str] = Field(default_factory=list)
    investor_name: str
    investor_description: Optional[str] = ""
    investor_industries: List[str] = Field(default_factory=list)
    investor_stages: List[str] = Field(default_factory=list)
    investor_min_investment: Optional[float] = None
    investor_max_investment: Optional[float] = None


class PredictResponse(BaseModel):
    decision: str
    probability: float
    match_percentage: float
    confidence_level: str
    positive_signals: List[str]
    negative_signals: List[str]
    explanation: str


class InvestorPayload(BaseModel):
    id: str = ""
    name: str = ""
    description: str = ""
    industries: List[str] = Field(default_factory=list)
    stages: List[str] = Field(default_factory=list)
    min_investment: Optional[float] = None
    max_investment: Optional[float] = None


class BulkRequest(BaseModel):
    project_description: str
    project_category: str
    funding_goal: float
    project_title: Optional[str] = ""
    project_stage: Optional[str] = ""
    project_tags: List[str] = Field(default_factory=list)
    investors: List[InvestorPayload]


class BulkResult(BaseModel):
    investor_id: str
    investor_name: str
    decision: str
    probability: float
    match_percentage: float
    confidence_level: str
    positive_signals: List[str]
    negative_signals: List[str]


@app.get("/")
def root():
    return {
        "status": "running",
        "engine": "semantic-embeddings",
        "model": EMBED_MODEL,
        "configured": bool(OPENAI_API_KEY),
    }


@app.get("/health")
def health():
    return {
        "status": "ok" if OPENAI_API_KEY else "missing_openai_key",
        "engine": "semantic-embeddings",
        "model": EMBED_MODEL,
        "threshold": MATCH_THRESHOLD,
        "configured": bool(OPENAI_API_KEY),
    }


@app.post("/predict", response_model=PredictResponse)
def predict(req: PredictRequest):
    _ensure_configured()

    project_text = _build_project_text(req)
    investor_text = _build_investor_text(req)
    project_vector, investor_vector = _embed_texts([project_text, investor_text])
    result = _score_match(
        project_vector=project_vector,
        investor_vector=investor_vector,
        project_category=req.project_category,
        project_stage=req.project_stage or "",
        funding_goal=req.funding_goal,
        investor_name=req.investor_name,
        investor_industries=req.investor_industries,
        investor_stages=req.investor_stages,
        min_investment=req.investor_min_investment,
        max_investment=req.investor_max_investment,
    )

    return PredictResponse(**result)


@app.post("/predict/bulk", response_model=List[BulkResult])
def predict_bulk(req: BulkRequest):
    _ensure_configured()
    if not req.investors:
        return []

    project_text = _build_project_text(req)
    investor_texts = [_build_bulk_investor_text(inv) for inv in req.investors]
    embeddings = _embed_texts([project_text, *investor_texts])
    project_vector = embeddings[0]
    investor_vectors = embeddings[1:]

    out: List[BulkResult] = []
    for inv, vector in zip(req.investors, investor_vectors):
        scored = _score_match(
            project_vector=project_vector,
            investor_vector=vector,
            project_category=req.project_category,
            project_stage=req.project_stage or "",
            funding_goal=req.funding_goal,
            investor_name=inv.name,
            investor_industries=inv.industries,
            investor_stages=inv.stages,
            min_investment=inv.min_investment,
            max_investment=inv.max_investment,
        )
        out.append(
            BulkResult(
                investor_id=inv.id,
                investor_name=inv.name,
                decision=scored["decision"],
                probability=scored["probability"],
                match_percentage=scored["match_percentage"],
                confidence_level=scored["confidence_level"],
                positive_signals=scored["positive_signals"],
                negative_signals=scored["negative_signals"],
            )
        )

    out.sort(key=lambda item: item.probability, reverse=True)
    return out


def _ensure_configured():
    if not OPENAI_API_KEY:
        raise HTTPException(
            status_code=503,
            detail="OPENAI_API_KEY is not configured for the semantic backend.",
        )


def _build_project_text(req: Any) -> str:
    parts = [
        f"Project title: {req.project_title}" if getattr(req, "project_title", "") else "",
        f"Project description: {req.project_description}" if req.project_description else "",
        f"Industry: {req.project_category}" if req.project_category else "",
        f"Stage: {getattr(req, 'project_stage', '')}" if getattr(req, "project_stage", "") else "",
        f"Tags: {', '.join(getattr(req, 'project_tags', []) or [])}"
        if getattr(req, "project_tags", [])
        else "",
    ]
    return " | ".join(part for part in parts if part)


def _build_investor_text(req: PredictRequest) -> str:
    parts = [
        f"Investor name: {req.investor_name}" if req.investor_name else "",
        f"Investor description: {req.investor_description}"
        if req.investor_description
        else "",
        f"Preferred industries: {', '.join(req.investor_industries)}"
        if req.investor_industries
        else "",
        f"Preferred stages: {', '.join(req.investor_stages)}" if req.investor_stages else "",
        _format_range(req.investor_min_investment, req.investor_max_investment),
    ]
    return " | ".join(part for part in parts if part)


def _build_bulk_investor_text(inv: InvestorPayload) -> str:
    parts = [
        f"Investor name: {inv.name}" if inv.name else "",
        f"Investor description: {inv.description}" if inv.description else "",
        f"Preferred industries: {', '.join(inv.industries)}" if inv.industries else "",
        f"Preferred stages: {', '.join(inv.stages)}" if inv.stages else "",
        _format_range(inv.min_investment, inv.max_investment),
    ]
    return " | ".join(part for part in parts if part)


def _format_range(min_investment: Optional[float], max_investment: Optional[float]) -> str:
    if min_investment is None and max_investment is None:
        return ""

    minimum = "any" if min_investment is None else f"{float(min_investment):.0f}"
    maximum = "any" if max_investment is None else f"{float(max_investment):.0f}"
    return f"Investment range: {minimum} to {maximum}"


def _embed_texts(texts: Iterable[str]) -> List[np.ndarray]:
    payload = {
        "model": EMBED_MODEL,
        "input": [text if text.strip() else "empty profile" for text in texts],
    }
    headers = {
        "Authorization": f"Bearer {OPENAI_API_KEY}",
        "Content-Type": "application/json",
    }

    with httpx.Client(timeout=HTTP_TIMEOUT) as client:
        response = client.post(f"{OPENAI_BASE_URL}/embeddings", json=payload, headers=headers)

    if response.status_code != 200:
        raise HTTPException(
            status_code=502,
            detail=f"Embedding request failed: {response.status_code} {response.text}",
        )

    body = response.json()
    data = body.get("data", [])
    if not data:
        raise HTTPException(status_code=502, detail="Embedding API returned no vectors.")

    ordered = sorted(data, key=lambda item: item["index"])
    return [np.array(item["embedding"], dtype=np.float32) for item in ordered]


def _score_match(
    *,
    project_vector: np.ndarray,
    investor_vector: np.ndarray,
    project_category: str,
    project_stage: str,
    funding_goal: float,
    investor_name: str,
    investor_industries: List[str],
    investor_stages: List[str],
    min_investment: Optional[float],
    max_investment: Optional[float],
) -> dict[str, Any]:
    raw_semantic_score = _cosine_similarity(project_vector, investor_vector)
    semantic_score = _calibrated_semantic_score(raw_semantic_score)
    industry_score = _industry_score(project_category, investor_industries)
    stage_score = _stage_score(project_stage, investor_stages)
    funding_score = _funding_score(funding_goal, min_investment, max_investment)

    probability = (
        (semantic_score * SEMANTIC_WEIGHT)
        + (industry_score * INDUSTRY_WEIGHT)
        + (stage_score * STAGE_WEIGHT)
        + (funding_score * FUNDING_WEIGHT)
    )

    if investor_industries and industry_score == 0.0:
        probability -= INDUSTRY_MISMATCH_PENALTY
    if investor_stages and stage_score == 0.0 and project_stage:
        probability -= STAGE_MISMATCH_PENALTY
    if (min_investment is not None or max_investment is not None) and funding_score < 1.0:
        probability -= FUNDING_MISMATCH_PENALTY

    probability = max(0.0, min(1.0, probability))

    positive_signals = []
    negative_signals = []

    if semantic_score >= 0.75:
        positive_signals.append("strong semantic alignment")
    elif semantic_score >= 0.45:
        positive_signals.append("good semantic alignment")
    else:
        negative_signals.append("weak semantic alignment")

    if industry_score >= 1.0:
        positive_signals.append("industry alignment")
    elif investor_industries:
        negative_signals.append("industry mismatch")

    if stage_score >= 1.0:
        positive_signals.append("stage alignment")
    elif investor_stages and project_stage:
        negative_signals.append("stage mismatch")

    if funding_score >= 1.0:
        positive_signals.append("funding range fit")
    elif min_investment is not None or max_investment is not None:
        negative_signals.append("funding range mismatch")

    decision = "INVEST" if probability >= MATCH_THRESHOLD else "SKIP"
    explanation = (
        f"{decision} - {probability * 100:.1f}% match with {investor_name}. "
        f"Semantic score {semantic_score * 100:.1f}%."
    )

    return {
        "decision": decision,
        "probability": round(probability, 4),
        "match_percentage": round(probability * 100, 1),
        "confidence_level": _confidence(probability),
        "positive_signals": positive_signals,
        "negative_signals": negative_signals,
        "explanation": explanation,
    }


def _cosine_similarity(left: np.ndarray, right: np.ndarray) -> float:
    left_norm = float(np.linalg.norm(left))
    right_norm = float(np.linalg.norm(right))
    if left_norm == 0.0 or right_norm == 0.0:
        return 0.0

    cosine = float(np.dot(left, right) / (left_norm * right_norm))
    return max(0.0, min(1.0, (cosine + 1.0) / 2.0))


def _calibrated_semantic_score(normalized_cosine: float) -> float:
    if normalized_cosine <= SEMANTIC_FLOOR:
        return 0.0
    if SEMANTIC_CEILING <= SEMANTIC_FLOOR:
        return max(0.0, min(1.0, normalized_cosine))

    return max(
        0.0,
        min(1.0, (normalized_cosine - SEMANTIC_FLOOR) / (SEMANTIC_CEILING - SEMANTIC_FLOOR)),
    )


def _industry_score(project_category: str, investor_industries: List[str]) -> float:
    if not project_category or not investor_industries:
        return 0.0

    normalized_project = _normalize_label(project_category)
    normalized_investors = {_normalize_label(value) for value in investor_industries if value}
    return 1.0 if normalized_project in normalized_investors else 0.0


def _stage_score(project_stage: str, investor_stages: List[str]) -> float:
    if not project_stage or not investor_stages:
        return 0.0

    normalized_project = _normalize_label(project_stage)
    normalized_stages = {_normalize_label(value) for value in investor_stages if value}
    return 1.0 if normalized_project in normalized_stages else 0.0


def _funding_score(
    funding_goal: float,
    min_investment: Optional[float],
    max_investment: Optional[float],
) -> float:
    if funding_goal <= 0:
        return 0.0

    if min_investment is None and max_investment is None:
        return 0.0

    lower = 0.0 if min_investment is None else float(min_investment)
    upper = math.inf if max_investment is None or max_investment <= 0 else float(max_investment)

    if lower <= funding_goal <= upper:
        return 1.0

    if funding_goal < lower and lower > 0:
        gap = (lower - funding_goal) / lower
        return max(0.0, 1.0 - gap)

    if upper not in (0.0, math.inf) and funding_goal > upper:
        gap = (funding_goal - upper) / upper
        return max(0.0, 1.0 - gap)

    return 0.0


def _normalize_label(value: str) -> str:
    return " ".join(value.strip().lower().replace("&", " and ").split())


def _confidence(probability: float) -> str:
    if probability >= 0.8 or probability <= 0.2:
        return "High"
    if probability >= 0.65 or probability <= 0.35:
        return "Medium"
    return "Low"
