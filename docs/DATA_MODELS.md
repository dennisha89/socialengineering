# Data Models & Database Schemas

## Overview
This document defines the data models for all services in the platform, including database schemas, relationships, and indexing strategies.

---

## 1. User Service (PostgreSQL)

### Table: users
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE,
    full_name VARCHAR(255),
    password_hash VARCHAR(255), -- bcrypt hash
    email_verified BOOLEAN DEFAULT FALSE,
    status VARCHAR(50) DEFAULT 'active', -- active, suspended, deleted
    subscription_tier VARCHAR(50) DEFAULT 'free', -- free, pro, enterprise
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    deleted_at TIMESTAMP NULL,
    
    -- Indexes
    INDEX idx_users_email (email),
    INDEX idx_users_username (username),
    INDEX idx_users_status (status),
    INDEX idx_users_created_at (created_at)
);
```

### Table: user_preferences
```sql
CREATE TABLE user_preferences (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    language VARCHAR(10) DEFAULT 'en',
    timezone VARCHAR(50) DEFAULT 'UTC',
    notification_email BOOLEAN DEFAULT TRUE,
    notification_push BOOLEAN DEFAULT TRUE,
    theme VARCHAR(20) DEFAULT 'light',
    currency VARCHAR(3) DEFAULT 'USD',
    preferences JSONB, -- flexible additional preferences
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

### Table: organizations
```sql
CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    owner_id UUID REFERENCES users(id),
    subscription_tier VARCHAR(50) DEFAULT 'free',
    billing_email VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    INDEX idx_org_slug (slug),
    INDEX idx_org_owner (owner_id)
);
```

### Table: organization_members
```sql
CREATE TABLE organization_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL, -- owner, admin, member, viewer
    invited_at TIMESTAMP,
    joined_at TIMESTAMP,
    status VARCHAR(50) DEFAULT 'active', -- invited, active, suspended
    
    UNIQUE(organization_id, user_id),
    INDEX idx_org_members_org (organization_id),
    INDEX idx_org_members_user (user_id)
);
```

---

## 2. Social Media Integration (PostgreSQL + MongoDB)

### PostgreSQL: social_accounts
```sql
CREATE TABLE social_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    platform VARCHAR(50) NOT NULL, -- instagram, twitter, facebook, tiktok, linkedin
    platform_user_id VARCHAR(255) NOT NULL,
    platform_username VARCHAR(255),
    display_name VARCHAR(255),
    profile_image_url TEXT,
    access_token_encrypted TEXT NOT NULL, -- encrypted with KMS
    refresh_token_encrypted TEXT,
    token_expires_at TIMESTAMP,
    scopes TEXT[], -- array of granted permissions
    status VARCHAR(50) DEFAULT 'active', -- active, expired, revoked, error
    last_synced_at TIMESTAMP,
    follower_count INTEGER DEFAULT 0,
    following_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(user_id, platform, platform_user_id),
    INDEX idx_social_user (user_id),
    INDEX idx_social_platform (platform),
    INDEX idx_social_status (status)
);
```

### MongoDB: followers (flexible schema)
```javascript
{
    _id: ObjectId("..."),
    social_account_id: "uuid",
    platform: "instagram",
    platform_follower_id: "123456789",
    username: "john_doe",
    display_name: "John Doe",
    bio: "Coffee lover ☕ | Travel addict 🌍",
    profile_image_url: "https://...",
    follower_count: 1500,
    following_count: 800,
    post_count: 250,
    verified: false,
    account_type: "personal", // personal, business, creator
    
    // Engagement metrics
    engagement: {
        avg_likes: 120,
        avg_comments: 15,
        engagement_rate: 0.09, // 9%
        last_post_date: ISODate("2025-11-15")
    },
    
    // Location data (if available)
    location: {
        city: "Los Angeles",
        country: "US",
        timezone: "America/Los_Angeles"
    },
    
    // Extracted metadata
    metadata: {
        language: "en",
        hashtags_used: ["coffee", "travel", "photography"],
        mentions_frequency: 0.3,
        posting_time_pattern: "evening", // morning, afternoon, evening, night
        content_types: ["image": 0.7, "video": 0.2, "carousel": 0.1]
    },
    
    // AI-analyzed data
    analysis: {
        interests: [
            {category: "food_beverage", subcategory: "coffee", confidence: 0.95},
            {category: "travel", subcategory: "adventure", confidence: 0.88},
            {category: "photography", subcategory: "landscape", confidence: 0.75}
        ],
        demographics: {
            age_range: "25-34",
            gender: "male", // inferred
            income_bracket: "middle",
            life_stage: "young_professional"
        },
        psychographics: {
            personality_traits: ["adventurous", "creative", "social"],
            values: ["authenticity", "experience", "community"],
            lifestyle: "urban_explorer"
        },
        purchase_intent: [
            {category: "travel_services", score: 0.82},
            {category: "coffee_products", score: 0.78},
            {category: "photography_gear", score: 0.65}
        ]
    },
    
    // Vector embeddings for similarity search
    embeddings: {
        profile_vector: [0.123, -0.456, 0.789, ...], // 768-dim
        interests_vector: [0.234, -0.567, 0.890, ...] // 384-dim
    },
    
    // Timestamps
    first_seen_at: ISODate("2025-10-01"),
    last_updated_at: ISODate("2025-11-17"),
    analyzed_at: ISODate("2025-11-17"),
    
    // Indexing
    // Compound index on: social_account_id + platform_follower_id
    // Index on: social_account_id, analysis.interests.category
    // Text index on: bio, display_name
}
```

### MongoDB: social_posts (sample data for analysis)
```javascript
{
    _id: ObjectId("..."),
    social_account_id: "uuid",
    platform: "instagram",
    post_id: "platform_post_id",
    author_id: "platform_user_id",
    type: "image", // image, video, carousel, story
    caption: "Amazing sunset in Bali 🌅 #travel #sunset #bali",
    media_urls: ["https://..."],
    hashtags: ["travel", "sunset", "bali"],
    mentions: ["@friend_username"],
    
    engagement: {
        likes: 450,
        comments: 32,
        shares: 15,
        saves: 28,
        views: 3200 // for videos
    },
    
    location: {
        name: "Bali, Indonesia",
        lat: -8.3405,
        lng: 115.0920
    },
    
    // AI analysis
    analysis: {
        topics: ["travel", "nature", "sunset"],
        sentiment: "positive",
        sentiment_score: 0.92,
        visual_tags: ["sunset", "ocean", "silhouette"],
        brand_mentions: [],
        language: "en"
    },
    
    posted_at: ISODate("2025-11-15T18:30:00Z"),
    collected_at: ISODate("2025-11-16T00:00:00Z")
}
```

---

## 3. Segmentation & Personas (PostgreSQL)

### Table: segments
```sql
CREATE TABLE segments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    social_account_id UUID REFERENCES social_accounts(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Segment criteria
    criteria JSONB NOT NULL, -- flexible filtering rules
    
    -- Segment size
    follower_count INTEGER DEFAULT 0,
    
    -- Segment quality metrics
    avg_engagement_rate DECIMAL(5,4),
    avg_follower_count INTEGER,
    reach_potential INTEGER,
    
    -- Status
    status VARCHAR(50) DEFAULT 'active', -- active, archived
    
    -- Regeneration tracking
    last_generated_at TIMESTAMP,
    generation_duration_seconds INTEGER,
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    INDEX idx_segments_user (user_id),
    INDEX idx_segments_social_account (social_account_id),
    INDEX idx_segments_status (status)
);
```

### Table: segment_members (junction table)
```sql
CREATE TABLE segment_members (
    segment_id UUID REFERENCES segments(id) ON DELETE CASCADE,
    follower_id VARCHAR(255), -- MongoDB ObjectId as string
    added_at TIMESTAMP DEFAULT NOW(),
    
    PRIMARY KEY (segment_id, follower_id),
    INDEX idx_segment_members_segment (segment_id)
);
```

### Table: personas
```sql
CREATE TABLE personas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    segment_id UUID REFERENCES segments(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Persona details (JSON for flexibility)
    demographics JSONB, -- age, gender, location, income, education
    psychographics JSONB, -- interests, values, personality, lifestyle
    behaviors JSONB, -- online behavior, purchase patterns, media consumption
    goals JSONB, -- user goals and motivations
    pain_points JSONB, -- challenges and frustrations
    
    -- Marketing insights
    messaging_angles TEXT[],
    preferred_channels TEXT[],
    best_posting_times JSONB,
    
    -- Representative follower (sample)
    representative_follower_id VARCHAR(255),
    
    -- Visuals
    avatar_url TEXT,
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    INDEX idx_personas_segment (segment_id)
);
```

---

## 4. Campaign Management (PostgreSQL)

### Table: campaigns
```sql
CREATE TABLE campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    
    name VARCHAR(255) NOT NULL,
    description TEXT,
    objective VARCHAR(100), -- awareness, engagement, conversions, traffic
    
    -- Targeting
    segment_id UUID REFERENCES segments(id),
    persona_id UUID REFERENCES personas(id),
    platforms TEXT[], -- which platforms to run on
    
    -- Budget
    budget_amount DECIMAL(10,2),
    budget_currency VARCHAR(3) DEFAULT 'USD',
    daily_budget DECIMAL(10,2),
    
    -- Schedule
    start_date TIMESTAMP,
    end_date TIMESTAMP,
    timezone VARCHAR(50) DEFAULT 'UTC',
    
    -- Status
    status VARCHAR(50) DEFAULT 'draft', -- draft, scheduled, active, paused, completed, cancelled
    
    -- Performance metrics (cached)
    impressions INTEGER DEFAULT 0,
    clicks INTEGER DEFAULT 0,
    conversions INTEGER DEFAULT 0,
    spend DECIMAL(10,2) DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    INDEX idx_campaigns_user (user_id),
    INDEX idx_campaigns_org (organization_id),
    INDEX idx_campaigns_status (status),
    INDEX idx_campaigns_dates (start_date, end_date)
);
```

### Table: ads
```sql
CREATE TABLE ads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_id UUID REFERENCES campaigns(id) ON DELETE CASCADE,
    
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50), -- image, video, carousel, story
    
    -- Creative content
    headline VARCHAR(255),
    body_text TEXT,
    cta_text VARCHAR(100), -- Call to action
    cta_url TEXT,
    
    -- Media
    media_urls TEXT[], -- S3 URLs
    thumbnail_url TEXT,
    
    -- Generation metadata
    generated_by VARCHAR(50), -- manual, ai_generated
    generation_prompt TEXT, -- if AI-generated
    model_used VARCHAR(100), -- gpt-4, claude-3.5, dalle-3, etc.
    
    -- A/B testing
    variant_group VARCHAR(100), -- for grouping test variants
    variant_name VARCHAR(50), -- A, B, C, etc.
    
    -- Performance metrics (cached)
    impressions INTEGER DEFAULT 0,
    clicks INTEGER DEFAULT 0,
    conversions INTEGER DEFAULT 0,
    spend DECIMAL(10,2) DEFAULT 0,
    ctr DECIMAL(5,4), -- Click-through rate
    cpc DECIMAL(10,2), -- Cost per click
    cpa DECIMAL(10,2), -- Cost per acquisition
    
    -- Status
    status VARCHAR(50) DEFAULT 'draft', -- draft, review, approved, active, paused, rejected
    approval_status VARCHAR(50),
    approval_notes TEXT,
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    INDEX idx_ads_campaign (campaign_id),
    INDEX idx_ads_status (status),
    INDEX idx_ads_variant (variant_group)
);
```

---

## 5. Analytics (TimescaleDB / PostgreSQL Extension)

### Table: campaign_metrics (hypertable)
```sql
CREATE TABLE campaign_metrics (
    time TIMESTAMP NOT NULL,
    campaign_id UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
    ad_id UUID REFERENCES ads(id) ON DELETE CASCADE,
    platform VARCHAR(50),
    
    -- Metrics
    impressions INTEGER DEFAULT 0,
    clicks INTEGER DEFAULT 0,
    conversions INTEGER DEFAULT 0,
    spend DECIMAL(10,2) DEFAULT 0,
    
    -- Derived metrics
    ctr DECIMAL(5,4),
    cpc DECIMAL(10,2),
    cpa DECIMAL(10,2),
    roas DECIMAL(10,2), -- Return on ad spend
    
    -- Dimensions
    country VARCHAR(2),
    device_type VARCHAR(50), -- desktop, mobile, tablet
    age_range VARCHAR(20),
    gender VARCHAR(20),
    
    PRIMARY KEY (time, campaign_id, ad_id)
);

-- Convert to hypertable for time-series optimization
SELECT create_hypertable('campaign_metrics', 'time');

-- Create continuous aggregate for hourly rollup
CREATE MATERIALIZED VIEW campaign_metrics_hourly
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 hour', time) AS hour,
    campaign_id,
    platform,
    SUM(impressions) as total_impressions,
    SUM(clicks) as total_clicks,
    SUM(conversions) as total_conversions,
    SUM(spend) as total_spend,
    AVG(ctr) as avg_ctr
FROM campaign_metrics
GROUP BY hour, campaign_id, platform;
```

### Table: engagement_events (high-volume)
```sql
CREATE TABLE engagement_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    time TIMESTAMP NOT NULL,
    event_type VARCHAR(50), -- impression, click, conversion, view
    
    campaign_id UUID REFERENCES campaigns(id) ON DELETE CASCADE,
    ad_id UUID REFERENCES ads(id) ON DELETE CASCADE,
    
    -- User context (anonymized)
    user_fingerprint VARCHAR(255), -- anonymized user ID
    session_id VARCHAR(255),
    
    -- Context
    platform VARCHAR(50),
    device_type VARCHAR(50),
    browser VARCHAR(100),
    os VARCHAR(100),
    country VARCHAR(2),
    city VARCHAR(100),
    referrer TEXT,
    
    -- Additional data
    metadata JSONB,
    
    created_at TIMESTAMP DEFAULT NOW()
);

-- Partition by time for performance
CREATE INDEX idx_events_time ON engagement_events (time DESC);
CREATE INDEX idx_events_campaign ON engagement_events (campaign_id, time DESC);
```

---

## 6. Billing (PostgreSQL)

### Table: subscriptions
```sql
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    
    plan_id VARCHAR(100) NOT NULL, -- free, pro_monthly, pro_annual, enterprise
    stripe_subscription_id VARCHAR(255) UNIQUE,
    stripe_customer_id VARCHAR(255),
    
    status VARCHAR(50), -- active, canceled, past_due, trialing
    
    -- Billing
    amount DECIMAL(10,2),
    currency VARCHAR(3) DEFAULT 'USD',
    billing_interval VARCHAR(50), -- monthly, annual
    
    -- Usage limits
    follower_sync_limit INTEGER,
    ad_generation_limit INTEGER,
    campaign_limit INTEGER,
    
    -- Dates
    trial_ends_at TIMESTAMP,
    current_period_start TIMESTAMP,
    current_period_end TIMESTAMP,
    canceled_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    INDEX idx_subscriptions_user (user_id),
    INDEX idx_subscriptions_org (organization_id),
    INDEX idx_subscriptions_status (status)
);
```

### Table: invoices
```sql
CREATE TABLE invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subscription_id UUID REFERENCES subscriptions(id),
    stripe_invoice_id VARCHAR(255) UNIQUE,
    
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    tax DECIMAL(10,2) DEFAULT 0,
    total DECIMAL(10,2) NOT NULL,
    
    status VARCHAR(50), -- draft, open, paid, void, uncollectible
    
    invoice_date DATE NOT NULL,
    due_date DATE,
    paid_at TIMESTAMP,
    
    invoice_pdf_url TEXT,
    
    created_at TIMESTAMP DEFAULT NOW(),
    
    INDEX idx_invoices_subscription (subscription_id),
    INDEX idx_invoices_status (status),
    INDEX idx_invoices_date (invoice_date DESC)
);
```

### Table: usage_records
```sql
CREATE TABLE usage_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES subscriptions(id),
    
    metric_type VARCHAR(100), -- follower_sync, ad_generation, api_call
    quantity INTEGER NOT NULL,
    
    timestamp TIMESTAMP NOT NULL,
    billing_period_start DATE,
    billing_period_end DATE,
    
    metadata JSONB,
    
    created_at TIMESTAMP DEFAULT NOW(),
    
    INDEX idx_usage_user (user_id, timestamp DESC),
    INDEX idx_usage_subscription (subscription_id, billing_period_start)
);
```

---

## 7. Job Queue (PostgreSQL or Redis)

### Table: jobs (if using PostgreSQL-based queue)
```sql
CREATE TABLE jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    queue_name VARCHAR(100) NOT NULL,
    job_type VARCHAR(100) NOT NULL,
    
    payload JSONB NOT NULL,
    
    status VARCHAR(50) DEFAULT 'queued', -- queued, processing, completed, failed, canceled
    priority INTEGER DEFAULT 0, -- higher = more priority
    
    attempts INTEGER DEFAULT 0,
    max_attempts INTEGER DEFAULT 3,
    
    error_message TEXT,
    error_stack TEXT,
    
    scheduled_at TIMESTAMP DEFAULT NOW(),
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    failed_at TIMESTAMP,
    
    -- Worker info
    worker_id VARCHAR(255),
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    INDEX idx_jobs_queue_status (queue_name, status, priority DESC, scheduled_at),
    INDEX idx_jobs_type (job_type),
    INDEX idx_jobs_created (created_at DESC)
);
```

---

## 8. Vector Database (Pinecone / Weaviate / Milvus)

### Collection: follower_embeddings

**Schema (Pinecone-like)**
```python
{
    "id": "follower_mongodb_id",
    "values": [0.123, -0.456, ...],  # 768-dimensional vector
    "metadata": {
        "social_account_id": "uuid",
        "platform": "instagram",
        "username": "john_doe",
        "interests": ["travel", "coffee", "photography"],
        "engagement_rate": 0.09,
        "follower_count": 1500,
        "last_updated": "2025-11-17T00:00:00Z"
    }
}
```

**Use Cases**:
- Find similar followers
- Semantic search by interests
- Audience expansion ("lookalike" audiences)
- Persona clustering

---

## 9. Caching Layer (Redis)

### Key Patterns

**User Sessions**
```
Key: session:{session_id}
Type: Hash
TTL: 24 hours
Value: {user_id, email, roles, ...}
```

**API Rate Limiting**
```
Key: ratelimit:{user_id}:{endpoint}
Type: String (counter)
TTL: 1 hour
```

**Social Media API Rate Limits**
```
Key: platform_limit:{platform}:{user_id}
Type: String (counter)
TTL: 1 hour
```

**Cached Follower Data**
```
Key: followers:{social_account_id}
Type: String (JSON)
TTL: 1 hour
```

**Cached Analytics**
```
Key: analytics:{campaign_id}:summary
Type: Hash
TTL: 30 seconds
```

**Job Queue (if using Redis for queue)**
```
Key: bull:queue_name:waiting
Type: List
```

---

## 10. Data Relationships Diagram

```
users (1) ─────< (*) social_accounts
              │
              └─────< (*) followers (MongoDB)
                         │
                         └─── has embeddings in Vector DB

users (1) ─────< (*) segments
              │
segments (1) ──< (*) personas
              │
segments (*) ──< (*) segment_members ──> (*) followers

users (1) ─────< (*) campaigns
              │
campaigns (1) ─< (*) ads
              │
campaigns (1) ─< (*) campaign_metrics
              │
ads (1) ───────< (*) engagement_events

users (1) ─────< (1) subscriptions
              │
subscriptions (1) ─< (*) invoices
              │
subscriptions (1) ─< (*) usage_records
```

---

## 11. Indexing Strategy

### PostgreSQL Indexes

**Composite Indexes** (most selective column first)
```sql
CREATE INDEX idx_campaigns_user_status ON campaigns (user_id, status);
CREATE INDEX idx_ads_campaign_status ON ads (campaign_id, status);
CREATE INDEX idx_segment_members_composite ON segment_members (segment_id, follower_id);
```

**Partial Indexes** (for specific queries)
```sql
CREATE INDEX idx_campaigns_active ON campaigns (user_id)
WHERE status = 'active';

CREATE INDEX idx_ads_pending_approval ON ads (campaign_id)
WHERE status = 'review';
```

**JSONB Indexes**
```sql
CREATE INDEX idx_personas_demographics ON personas
USING GIN (demographics jsonb_path_ops);

CREATE INDEX idx_segments_criteria ON segments
USING GIN (criteria jsonb_path_ops);
```

### MongoDB Indexes

```javascript
// followers collection
db.followers.createIndex({ social_account_id: 1, platform_follower_id: 1 }, { unique: true });
db.followers.createIndex({ "analysis.interests.category": 1 });
db.followers.createIndex({ "engagement.engagement_rate": -1 });
db.followers.createIndex({ analyzed_at: -1 });
db.followers.createIndex({ bio: "text", display_name: "text" });

// social_posts collection
db.social_posts.createIndex({ social_account_id: 1, posted_at: -1 });
db.social_posts.createIndex({ author_id: 1 });
db.social_posts.createIndex({ "analysis.topics": 1 });
```

---

## 12. Data Retention Policies

| Data Type | Retention | Archive Strategy |
|-----------|-----------|------------------|
| User accounts | Indefinite | Soft delete + anonymize after 30 days |
| Follower data | 1 year | Archive to S3 Glacier |
| Raw social posts | 90 days | Delete |
| Campaign data | 2 years | Compress + archive |
| Analytics (detailed) | 90 days | Aggregate to hourly/daily |
| Analytics (aggregated) | 2 years | Archive to data warehouse |
| Logs | 30 days | Archive to S3 |
| Generated ads | 1 year | Archive to S3 Glacier |
| Job records | 7 days | Delete |

**Automated Cleanup Jobs**
- Daily: Delete old job records, expired sessions
- Weekly: Archive old analytics data
- Monthly: Archive old follower data, compress campaign data

---

## 13. Data Migration Strategy

**Version Control**
- Use migration tools: Flyway (Java), Alembic (Python), or Prisma Migrate
- Migrations versioned and stored in Git
- Rollback capability for every migration

**Zero-downtime Migrations**
1. Backward-compatible schema changes first
2. Deploy application code
3. Run data migration in background
4. Clean up old columns/tables after verification

**Example: Adding a new column**
```sql
-- Step 1: Add column (nullable)
ALTER TABLE campaigns ADD COLUMN new_field VARCHAR(255);

-- Step 2: Backfill data (in batches)
UPDATE campaigns SET new_field = ... WHERE id IN (...);

-- Step 3: Make NOT NULL (after verification)
ALTER TABLE campaigns ALTER COLUMN new_field SET NOT NULL;
```

---

## Summary

This data model provides:
- **Scalability**: Sharded MongoDB, partitioned PostgreSQL tables
- **Flexibility**: JSONB for evolving schemas
- **Performance**: Strategic indexing, caching layer
- **Compliance**: Data retention policies, soft deletes
- **Maintainability**: Clear relationships, version-controlled migrations

The hybrid PostgreSQL + MongoDB approach balances transactional integrity (campaigns, billing) with flexible schema needs (social media data).

