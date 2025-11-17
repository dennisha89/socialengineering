"""
Main FastAPI application for AI/ML pipeline
"""

from fastapi import FastAPI, HTTPException, Depends, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from pydantic import BaseModel
from typing import List, Optional, Dict
import logging
from datetime import datetime

from app.services.ml_service import MLService
from app.services.ad_generator import AdGeneratorService
from app.services.moderation import ContentModerationService
from app.utils.auth import get_current_user
from app.utils.rate_limiter import RateLimiter
from app.utils.cache import CacheManager

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="Social Engineering ML Pipeline API",
    description="AI/ML pipeline for follower analysis and ad generation",
    version="1.0.0"
)

# Add middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.add_middleware(GZipMiddleware, minimum_size=1000)

# Initialize services
ml_service = MLService()
ad_service = AdGeneratorService()
moderation_service = ContentModerationService()
cache_manager = CacheManager()
rate_limiter = RateLimiter()

# Pydantic models
class UserAnalysisRequest(BaseModel):
    user_id: str
    platform: str
    include_ads: bool = True
    force_refresh: bool = False

class UserAnalysisResponse(BaseModel):
    user_id: str
    platform: str
    sentiment: Dict
    cluster: int
    persona_id: str
    interests: List[str]
    engagement_score: float
    recommended_ads: Optional[List[Dict]] = None
    processed_at: datetime

class AdGenerationRequest(BaseModel):
    persona_id: str
    product_id: str
    num_variations: int = 3
    quality_requirement: str = "medium"  # low, medium, high, premium

class AdVariation(BaseModel):
    id: str
    headline: str
    body: str
    cta: str
    image_url: Optional[str] = None
    quality_score: float
    variant_type: str  # emotional, rational, social_proof, urgency, value

class AdGenerationResponse(BaseModel):
    persona_id: str
    product_id: str
    variations: List[AdVariation]
    generated_at: datetime

class BatchAnalysisRequest(BaseModel):
    user_ids: List[str]
    platform: str

# Health check
@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "services": {
            "ml_service": "operational",
            "ad_service": "operational",
            "moderation": "operational"
        }
    }

# User analysis endpoints
@app.post("/api/v1/analyze_user", response_model=UserAnalysisResponse)
async def analyze_user(
    request: UserAnalysisRequest,
    background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user)
):
    """
    Analyze a social media user and generate persona
    """
    try:
        # Check rate limit
        await rate_limiter.check_limit(current_user["user_id"], "analyze_user")
        
        # Check cache
        if not request.force_refresh:
            cached_result = await cache_manager.get(
                f"user_analysis:{request.user_id}:{request.platform}"
            )
            if cached_result:
                logger.info(f"Cache hit for user {request.user_id}")
                return cached_result
        
        # Perform analysis
        logger.info(f"Analyzing user {request.user_id} on {request.platform}")
        
        analysis_result = await ml_service.analyze_user(
            user_id=request.user_id,
            platform=request.platform
        )
        
        # Generate ads if requested
        if request.include_ads:
            background_tasks.add_task(
                generate_ads_background,
                analysis_result["persona_id"],
                request.user_id
            )
        
        # Cache result
        await cache_manager.set(
            f"user_analysis:{request.user_id}:{request.platform}",
            analysis_result,
            ttl=3600
        )
        
        return analysis_result
        
    except Exception as e:
        logger.error(f"Error analyzing user: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/generate_ads", response_model=AdGenerationResponse)
async def generate_ads(
    request: AdGenerationRequest,
    current_user: dict = Depends(get_current_user)
):
    """
    Generate personalized ad variations
    """
    try:
        # Check rate limit
        await rate_limiter.check_limit(current_user["user_id"], "generate_ads")
        
        # Check cache
        cache_key = f"ads:{request.persona_id}:{request.product_id}"
        cached_ads = await cache_manager.get(cache_key)
        
        if cached_ads:
            logger.info(f"Cache hit for ads {cache_key}")
            return cached_ads
        
        # Generate ads
        logger.info(f"Generating ads for persona {request.persona_id}")
        
        ad_variations = await ad_service.generate_ad_variations(
            persona_id=request.persona_id,
            product_id=request.product_id,
            num_variations=request.num_variations,
            quality_requirement=request.quality_requirement
        )
        
        # Moderate content
        moderated_ads = []
        for ad in ad_variations:
            moderation_result = await moderation_service.moderate_ad(ad)
            if moderation_result["approved"]:
                moderated_ads.append(ad)
            else:
                logger.warning(f"Ad rejected: {moderation_result['flags']}")
        
        response = AdGenerationResponse(
            persona_id=request.persona_id,
            product_id=request.product_id,
            variations=moderated_ads,
            generated_at=datetime.utcnow()
        )
        
        # Cache for 24 hours
        await cache_manager.set(cache_key, response, ttl=86400)
        
        return response
        
    except Exception as e:
        logger.error(f"Error generating ads: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/batch_analyze")
async def batch_analyze_users(
    request: BatchAnalysisRequest,
    background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user)
):
    """
    Batch analyze multiple users (async processing)
    """
    try:
        # Queue batch job
        job_id = await ml_service.queue_batch_analysis(
            user_ids=request.user_ids,
            platform=request.platform
        )
        
        return {
            "job_id": job_id,
            "status": "queued",
            "user_count": len(request.user_ids),
            "message": "Batch analysis queued. Check status at /api/v1/batch_status/{job_id}"
        }
        
    except Exception as e:
        logger.error(f"Error queueing batch analysis: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/batch_status/{job_id}")
async def get_batch_status(
    job_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Get status of batch analysis job
    """
    try:
        status = await ml_service.get_batch_status(job_id)
        return status
        
    except Exception as e:
        logger.error(f"Error getting batch status: {str(e)}")
        raise HTTPException(status_code=404, detail="Job not found")

@app.get("/api/v1/personas/{cluster_id}")
async def get_persona(
    cluster_id: int,
    current_user: dict = Depends(get_current_user)
):
    """
    Get persona for a cluster
    """
    try:
        persona = await ml_service.get_persona(cluster_id)
        return persona
        
    except Exception as e:
        logger.error(f"Error getting persona: {str(e)}")
        raise HTTPException(status_code=404, detail="Persona not found")

@app.post("/api/v1/track_event")
async def track_event(
    user_id: str,
    experiment_id: str,
    metric_name: str,
    value: float
):
    """
    Track A/B testing event
    """
    try:
        await ml_service.track_ab_test_event(
            user_id=user_id,
            experiment_id=experiment_id,
            metric_name=metric_name,
            value=value
        )
        
        return {"status": "tracked"}
        
    except Exception as e:
        logger.error(f"Error tracking event: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/experiment_results/{experiment_id}")
async def get_experiment_results(
    experiment_id: str,
    current_user: dict = Depends(get_current_user)
):
    """
    Get A/B test experiment results
    """
    try:
        results = await ml_service.get_experiment_results(experiment_id)
        return results
        
    except Exception as e:
        logger.error(f"Error getting experiment results: {str(e)}")
        raise HTTPException(status_code=404, detail="Experiment not found")

# Metrics endpoint for Prometheus
@app.get("/metrics")
async def metrics():
    """
    Prometheus metrics endpoint
    """
    from prometheus_client import generate_latest, CONTENT_TYPE_LATEST
    from fastapi.responses import Response
    
    return Response(
        generate_latest(),
        media_type=CONTENT_TYPE_LATEST
    )

# Background tasks
async def generate_ads_background(persona_id: str, user_id: str):
    """
    Background task for ad generation
    """
    try:
        logger.info(f"Background ad generation for persona {persona_id}")
        # Implementation
        pass
    except Exception as e:
        logger.error(f"Background task failed: {str(e)}")

# Startup event
@app.on_event("startup")
async def startup_event():
    """
    Initialize services on startup
    """
    logger.info("Starting ML Pipeline API...")
    await ml_service.initialize()
    await ad_service.initialize()
    await moderation_service.initialize()
    logger.info("All services initialized successfully")

# Shutdown event
@app.on_event("shutdown")
async def shutdown_event():
    """
    Cleanup on shutdown
    """
    logger.info("Shutting down ML Pipeline API...")
    await ml_service.cleanup()
    await ad_service.cleanup()
    logger.info("Shutdown complete")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
