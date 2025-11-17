"""
Simple MVP Backend - Follower Intelligence & Ad Generation
No over-engineering, just working code.
"""

from fastapi import FastAPI, UploadFile, File, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import openai
import pandas as pd
import sqlite3
import json
from datetime import datetime
import os
from io import StringIO

app = FastAPI(title="Follower Intelligence MVP")

# CORS for frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Database setup
def get_db():
    conn = sqlite3.connect('followers.db')
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    """Initialize SQLite database"""
    conn = get_db()
    conn.execute("""
        CREATE TABLE IF NOT EXISTS analyses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT,
            platform TEXT DEFAULT 'instagram',
            follower_count INTEGER,
            insights TEXT,
            top_interests TEXT,
            demographics TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)
    conn.execute("""
        CREATE TABLE IF NOT EXISTS ads (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            analysis_id INTEGER,
            topic TEXT,
            ad_copy TEXT,
            headline TEXT,
            cta TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (analysis_id) REFERENCES analyses(id)
        )
    """)
    conn.commit()
    conn.close()

init_db()

# OpenAI setup
openai.api_key = os.getenv("OPENAI_API_KEY", "")

# Pydantic models
class FollowerAnalysisRequest(BaseModel):
    platform: str = "instagram"
    user_id: Optional[str] = None

class AdGenerationRequest(BaseModel):
    analysis_id: int
    topic: str
    tone: str = "casual"

class FollowerData(BaseModel):
    username: str
    bio: str
    follower_count: Optional[int] = None
    following_count: Optional[int] = None

# ============================================
# CORE FEATURES - TIER 1
# ============================================

@app.get("/")
def read_root():
    return {
        "message": "Follower Intelligence MVP API",
        "version": "1.0.0",
        "endpoints": {
            "analyze": "/api/analyze-followers",
            "generate_ad": "/api/generate-ad",
            "history": "/api/history"
        }
    }

@app.post("/api/analyze-followers")
async def analyze_followers(file: UploadFile = File(...)):
    """
    Upload CSV of followers and get AI-powered insights

    CSV Format: username, bio, follower_count, following_count
    """
    try:
        # Read CSV
        contents = await file.read()
        df = pd.read_csv(StringIO(contents.decode('utf-8')))

        if 'bio' not in df.columns:
            raise HTTPException(status_code=400, detail="CSV must have 'bio' column")

        # Take first 100 followers (to keep costs low)
        sample = df.head(100)
        bios = sample['bio'].dropna().tolist()

        if not bios:
            raise HTTPException(status_code=400, detail="No bios found in CSV")

        # AI Analysis using GPT-4
        prompt = f"""
        Analyze these {len(bios)} follower bios from Instagram and provide detailed insights:

        Bios:
        {chr(10).join(bios[:50])}

        Provide your analysis in this exact JSON format:
        {{
            "top_interests": ["interest1", "interest2", "interest3", "interest4", "interest5"],
            "age_range": "estimated age range",
            "geographic_hints": ["location1", "location2"],
            "personality_traits": ["trait1", "trait2", "trait3"],
            "pain_points": ["pain1", "pain2", "pain3"],
            "ad_angles": ["angle1", "angle2", "angle3"],
            "content_preferences": ["type1", "type2", "type3"],
            "summary": "2-3 sentence summary of this audience"
        }}
        """

        response = openai.ChatCompletion.create(
            model="gpt-4",
            messages=[
                {"role": "system", "content": "You are a social media audience analyst. Always respond with valid JSON only."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.7,
            max_tokens=800
        )

        analysis = response.choices[0].message.content

        # Parse JSON response
        try:
            insights = json.loads(analysis)
        except:
            # Fallback if GPT doesn't return perfect JSON
            insights = {"summary": analysis, "top_interests": [], "ad_angles": []}

        # Save to database
        conn = get_db()
        cursor = conn.execute("""
            INSERT INTO analyses (user_id, platform, follower_count, insights, top_interests, demographics)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (
            file.filename,
            'instagram',
            len(df),
            json.dumps(insights),
            json.dumps(insights.get('top_interests', [])),
            json.dumps({
                'age_range': insights.get('age_range', ''),
                'locations': insights.get('geographic_hints', [])
            })
        ))
        conn.commit()
        analysis_id = cursor.lastrowid
        conn.close()

        return {
            "success": True,
            "analysis_id": analysis_id,
            "follower_count": len(df),
            "analyzed_count": len(bios),
            "insights": insights,
            "cost_estimate": f"${len(bios) * 0.005:.2f}"  # Rough estimate
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/generate-ad")
async def generate_ad(request: AdGenerationRequest):
    """
    Generate personalized ad copy based on follower analysis
    """
    try:
        # Get analysis from database
        conn = get_db()
        analysis = conn.execute(
            "SELECT * FROM analyses WHERE id = ?",
            (request.analysis_id,)
        ).fetchone()

        if not analysis:
            raise HTTPException(status_code=404, detail="Analysis not found")

        insights = json.loads(analysis['insights'])
        interests = insights.get('top_interests', [])
        pain_points = insights.get('pain_points', [])
        ad_angles = insights.get('ad_angles', [])

        # Generate ad with GPT-4
        prompt = f"""
        Create a high-converting Facebook/Instagram ad for: {request.topic}

        Target Audience Insights:
        - Interests: {', '.join(interests)}
        - Pain Points: {', '.join(pain_points)}
        - Best Angles: {', '.join(ad_angles)}
        - Tone: {request.tone}

        Generate:
        1. Attention-grabbing headline (max 40 characters)
        2. Primary text (125-150 words, emotional, benefit-focused)
        3. Call-to-action (short, action-oriented)

        Respond in JSON format:
        {{
            "headline": "...",
            "primary_text": "...",
            "cta": "...",
            "why_it_works": "brief explanation"
        }}
        """

        response = openai.ChatCompletion.create(
            model="gpt-4",
            messages=[
                {"role": "system", "content": "You are an expert direct response copywriter. Always respond with valid JSON only."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.8,
            max_tokens=500
        )

        ad_content = json.loads(response.choices[0].message.content)

        # Save ad to database
        cursor = conn.execute("""
            INSERT INTO ads (analysis_id, topic, ad_copy, headline, cta)
            VALUES (?, ?, ?, ?, ?)
        """, (
            request.analysis_id,
            request.topic,
            ad_content.get('primary_text', ''),
            ad_content.get('headline', ''),
            ad_content.get('cta', '')
        ))
        conn.commit()
        ad_id = cursor.lastrowid
        conn.close()

        return {
            "success": True,
            "ad_id": ad_id,
            "ad_content": ad_content,
            "based_on_analysis": request.analysis_id
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/history")
async def get_history(limit: int = 10):
    """Get recent analyses and generated ads"""
    conn = get_db()

    # Get recent analyses
    analyses = conn.execute("""
        SELECT id, user_id, platform, follower_count,
               insights, created_at
        FROM analyses
        ORDER BY created_at DESC
        LIMIT ?
    """, (limit,)).fetchall()

    results = []
    for analysis in analyses:
        # Get ads for this analysis
        ads = conn.execute("""
            SELECT id, topic, headline, cta, created_at
            FROM ads
            WHERE analysis_id = ?
            ORDER BY created_at DESC
        """, (analysis['id'],)).fetchall()

        results.append({
            "id": analysis['id'],
            "user_id": analysis['user_id'],
            "platform": analysis['platform'],
            "follower_count": analysis['follower_count'],
            "insights": json.loads(analysis['insights']),
            "created_at": analysis['created_at'],
            "ads_generated": len(ads),
            "ads": [dict(ad) for ad in ads]
        })

    conn.close()
    return {"history": results}


@app.get("/api/analysis/{analysis_id}")
async def get_analysis(analysis_id: int):
    """Get specific analysis details"""
    conn = get_db()
    analysis = conn.execute(
        "SELECT * FROM analyses WHERE id = ?",
        (analysis_id,)
    ).fetchone()

    if not analysis:
        raise HTTPException(status_code=404, detail="Analysis not found")

    # Get related ads
    ads = conn.execute("""
        SELECT * FROM ads WHERE analysis_id = ? ORDER BY created_at DESC
    """, (analysis_id,)).fetchall()

    conn.close()

    return {
        "id": analysis['id'],
        "user_id": analysis['user_id'],
        "platform": analysis['platform'],
        "follower_count": analysis['follower_count'],
        "insights": json.loads(analysis['insights']),
        "created_at": analysis['created_at'],
        "ads": [dict(ad) for ad in ads]
    }


@app.get("/api/stats")
async def get_stats():
    """Dashboard statistics"""
    conn = get_db()

    total_analyses = conn.execute("SELECT COUNT(*) FROM analyses").fetchone()[0]
    total_ads = conn.execute("SELECT COUNT(*) FROM ads").fetchone()[0]
    total_followers = conn.execute("SELECT SUM(follower_count) FROM analyses").fetchone()[0] or 0

    recent = conn.execute("""
        SELECT DATE(created_at) as date, COUNT(*) as count
        FROM analyses
        GROUP BY DATE(created_at)
        ORDER BY date DESC
        LIMIT 7
    """).fetchall()

    conn.close()

    return {
        "total_analyses": total_analyses,
        "total_ads_generated": total_ads,
        "total_followers_analyzed": total_followers,
        "activity_last_7_days": [dict(r) for r in recent]
    }


# Health check
@app.get("/health")
def health_check():
    return {"status": "healthy", "timestamp": datetime.utcnow().isoformat()}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
