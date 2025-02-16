import os
import logging
import json
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Any, Optional
from logging.handlers import RotatingFileHandler
from pythonjsonlogger import jsonlogger
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from langchain_community.vectorstores import OpenSearch
from langchain.embeddings import OllamaEmbeddings
from langchain.cache import RedisCache
import langchain
import redis
import tenacity
from prometheus_client import start_http_server, Counter, Histogram
from dotenv import load_dotenv

# Завантаження змінних середовища
load_dotenv()

# Налаштування логування
log_dir = Path("/app/logs")
log_dir.mkdir(exist_ok=True)

logger = logging.getLogger("app")
logHandler = RotatingFileHandler(
    log_dir / "app.log",
    maxBytes=5 * 1024 * 1024,  # 5MB
    backupCount=5
)
formatter = jsonlogger.JsonFormatter(
    '%(asctime)s %(levelname)s %(name)s %(message)s'
)
logHandler.setFormatter(formatter)
logger.addHandler(logHandler)
logger.setLevel(os.getenv("LOG_LEVEL", "INFO"))

# Метрики Prometheus
SEARCH_DURATION = Histogram(
    'search_duration_seconds',
    'Time spent processing search requests'
)
SEARCH_ERRORS = Counter(
    'search_errors_total',
    'Total number of search errors'
)
CACHE_HITS = Counter(
    'cache_hits_total',
    'Total number of cache hits'
)

# Ініціалізація FastAPI
app = FastAPI(title="LangChain Search API")

# Налаштування Redis кешу
redis_client = redis.Redis.from_url(
    os.getenv("REDIS_URL", "redis://redis:6379/0"),
    decode_responses=True
)
langchain.llm_cache = RedisCache(redis_client)

# Налаштування OpenSearch
vectorstore = OpenSearch(
    index_name="customs_declarations-*",
    opensearch_url=os.getenv("OPENSEARCH_HOST", "http://opensearch:9200"),
    http_auth=(
        os.getenv("OPENSEARCH_USERNAME", "admin"),
        os.getenv("OPENSEARCH_PASSWORD", "admin")
    ),
    use_ssl=False,
    verify_certs=False,
    ssl_assert_hostname=False,
    ssl_show_warn=False
)

# Ініціалізація Ollama з оптимізованими налаштуваннями для M1
embeddings = OllamaEmbeddings(
    model="tulu3",
    base_url=os.getenv("OLLAMA_HOST", "http://host.docker.internal:11434"),
    temperature=0.3,
    timeout=30,
    retry_on_timeout=True,
    cache=True
)

class SearchQuery(BaseModel):
    query: str
    limit: Optional[int] = 5
    min_score: Optional[float] = 0.0

class SearchResponse(BaseModel):
    results: List[Dict[str, Any]]
    total: int
    took: float

@app.get("/health")
async def health_check():
    """Перевірка здоров'я сервісу"""
    try:
        # Перевірка підключення до Redis
        redis_client.ping()
        
        # Перевірка підключення до OpenSearch
        vectorstore.client.info()
        
        # Перевірка доступності Ollama
        embeddings.embed_query("test")
        
        return {"status": "healthy"}
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        raise HTTPException(status_code=503, detail=str(e))

@tenacity.retry(
    stop=tenacity.stop_after_attempt(3),
    wait=tenacity.wait_exponential(multiplier=1, min=4, max=10),
    retry=tenacity.retry_if_exception_type(Exception),
    before_sleep=lambda retry_state: logger.warning(
        f"Retrying after error: {retry_state.outcome.exception()}"
    )
)
@SEARCH_DURATION.time()
async def search_declarations(query: SearchQuery) -> SearchResponse:
    """
    Пошук митних декларацій
    
    Args:
        query (SearchQuery): Параметри пошуку
        
    Returns:
        SearchResponse: Результати пошуку
    """
    try:
        # Спроба отримати результати з кешу
        cache_key = f"search:{query.query}:{query.limit}:{query.min_score}"
        cached_result = redis_client.get(cache_key)
        
        if cached_result:
            CACHE_HITS.inc()
            return SearchResponse(**json.loads(cached_result))
        
        # Виконання пошуку
        start_time = datetime.now()
        results = vectorstore.similarity_search(
            query=query.query,
            k=query.limit,
            embeddings=embeddings
        )
        
        # Форматування результатів
        formatted_results = []
        for doc in results:
            if doc.metadata.get("score", 0) >= query.min_score:
                formatted_results.append({
                    "content": doc.page_content,
                    "metadata": doc.metadata
                })
        
        # Створення відповіді
        response = SearchResponse(
            results=formatted_results,
            total=len(formatted_results),
            took=(datetime.now() - start_time).total_seconds()
        )
        
        # Збереження в кеш
        redis_client.setex(
            cache_key,
            3600,  # TTL 1 година
            json.dumps(response.dict())
        )
        
        return response
    except Exception as e:
        SEARCH_ERRORS.inc()
        logger.error(f"Search error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/search", response_model=SearchResponse)
async def search_endpoint(query: SearchQuery):
    """API endpoint для пошуку"""
    return await search_declarations(query)

@app.on_event("startup")
async def startup_event():
    """Ініціалізація при запуску"""
    # Запуск Prometheus метрик
    start_http_server(8000)
    logger.info("Application started")

@app.on_event("shutdown")
async def shutdown_event():
    """Очищення при зупинці"""
    try:
        redis_client.close()
        logger.info("Application shutdown complete")
    except Exception as e:
        logger.error(f"Error during shutdown: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app:app",
        host="0.0.0.0",
        port=5000,
        workers=4,
        log_level="info",
        reload=True
    )
