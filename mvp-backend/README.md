# Follower Intelligence MVP - Backend

Simple, working backend for follower analysis and ad generation.

## What This Does

1. **Analyze Followers**: Upload a CSV of Instagram followers, get AI-powered insights
2. **Generate Ads**: Create personalized ad copy based on follower analysis
3. **Track History**: View past analyses and generated ads

## Quick Start

```bash
# 1. Install dependencies
pip install -r requirements.txt

# 2. Set up OpenAI API key
cp .env.example .env
# Edit .env and add your OpenAI API key

# 3. Run the server
python main.py
```

Server runs at: http://localhost:8000

## API Endpoints

### Analyze Followers
```bash
POST /api/analyze-followers
Content-Type: multipart/form-data

Upload a CSV file with columns: username, bio, follower_count, following_count
```

### Generate Ad
```bash
POST /api/generate-ad
Content-Type: application/json

{
  "analysis_id": 1,
  "topic": "fitness coaching",
  "tone": "casual"
}
```

### Get History
```bash
GET /api/history?limit=10
```

### Get Stats
```bash
GET /api/stats
```

## How to Get Follower Data

### Manual Method (Works Now):
1. Go to Instagram profile
2. Click "Followers"
3. Manually copy some bios into Excel/CSV
4. Upload to this app

### Future: Automated (Coming Soon)
- Instagram API integration
- Auto-sync followers
- Real-time updates

## Cost

- **Per Analysis**: ~$0.10-0.50 (depends on follower count)
- **Per Ad Generation**: ~$0.05-0.10
- **Hosting**: Free (Railway/Render) or $7/month (Heroku)

## Database

Uses SQLite (file: `followers.db`)
- Simple, no setup required
- Perfect for MVP
- Can migrate to PostgreSQL later when scaling

## What's NOT Included (Intentionally)

- ❌ No Kubernetes
- ❌ No microservices
- ❌ No Docker (unless you want it)
- ❌ No complex auth (add later)
- ❌ No multi-platform (Instagram only for now)

This is about shipping fast, not over-engineering.

## Next Steps

1. Test locally
2. Deploy to Railway/Render (5 minutes)
3. Get first customer
4. Iterate based on feedback
