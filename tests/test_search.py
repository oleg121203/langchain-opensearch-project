import pytest
from httpx import AsyncClient
import json
from app import app

@pytest.mark.asyncio
async def test_health_endpoint():
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.get("/health")
        assert response.status_code == 200
        assert response.json()["status"] == "healthy"

@pytest.mark.asyncio
async def test_search_endpoint():
    async with AsyncClient(app=app, base_url="http://test") as client:
        query = {
            "query": "test query",
            "limit": 5,
            "min_score": 0.0
        }
        response = await client.post("/search", json=query)
        assert response.status_code == 200
        data = response.json()
        assert "results" in data
        assert "total" in data
        assert "took" in data

@pytest.mark.asyncio
async def test_search_with_invalid_query():
    async with AsyncClient(app=app, base_url="http://test") as client:
        query = {
            "query": "",  # Пустий запит
            "limit": -1   # Некоректний ліміт
        }
        response = await client.post("/search", json=query)
        assert response.status_code == 422  # Validation error

@pytest.mark.asyncio
async def test_search_with_high_limit():
    async with AsyncClient(app=app, base_url="http://test") as client:
        query = {
            "query": "test query",
            "limit": 1000  # Завеликий ліміт
        }
        response = await client.post("/search", json=query)
        assert response.status_code == 200
        data = response.json()
        assert len(data["results"]) <= 100  # Перевірка обмеження результатів