# Database Architecture for AI-Powered Follower Intelligence & Ad Generation System

## Executive Summary

This document outlines the complete database architecture for a multi-platform social intelligence and ad generation system that processes follower data, behavioral patterns, AI-generated insights, and ad campaign performance.

## 1. Technology Stack Recommendations

### 1.1 Hybrid Database Approach

We recommend a **polyglot persistence** strategy using multiple specialized databases:

#### Primary Transactional Database: **PostgreSQL 15+**
- **Use Cases**: User accounts, campaigns, ad content, relationships
- **Rationale**: 
  - ACID compliance for critical business data
  - Strong JSON/JSONB support for flexible schema
  - Excellent query optimizer
  - Mature ecosystem and tooling
  - PostGIS for geo-targeting features
  - Full-text search capabilities

#### Time-Series Database: **TimescaleDB** (PostgreSQL Extension)
- **Use Cases**: Engagement metrics, performance tracking, behavioral patterns
- **Rationale**:
  - Built on PostgreSQL (unified management)
  - Automatic partitioning and retention policies
  - Optimized for time-series queries and aggregations
  - Continuous aggregates for real-time dashboards
  - Native compression (10-20x reduction)

#### Document Store: **MongoDB 6+**
- **Use Cases**: Social platform raw data, AI training datasets, unstructured content
- **Rationale**:
  - Flexible schema for varying social platform APIs
  - Horizontal scaling for large datasets
  - Efficient storage of nested/hierarchical data
  - Change streams for real-time processing
  - Aggregation pipeline for complex analytics

#### Search Engine: **Elasticsearch 8+**
- **Use Cases**: Full-text search on followers, content, personas
- **Rationale**:
  - Powerful text analysis and NLP capabilities
  - Fast fuzzy matching and autocomplete
  - Analytics aggregations
  - Integration with AI/ML features

#### Cache Layer: **Redis 7+**
- **Use Cases**: Session management, rate limiting, computed results, pub/sub
- **Rationale**:
  - In-memory speed for hot data
  - Multiple data structures (strings, hashes, sorted sets, streams)
  - Built-in pub/sub for real-time updates
  - Redis Streams for event processing
  - RedisJSON for complex cached objects
  - RedisTimeSeries for short-term metrics

#### Object Storage: **S3-Compatible Storage** (AWS S3, MinIO, GCS)
- **Use Cases**: Media files, AI model artifacts, data exports
- **Rationale**:
  - Unlimited scalability
  - Cost-effective for large files
  - Versioning and lifecycle management
  - Integration with analytics tools

#### Data Warehouse: **Snowflake** or **Google BigQuery**
- **Use Cases**: Historical analytics, BI reporting, ML training datasets
- **Rationale**:
  - Separation of storage and compute
  - Columnar storage for analytics
  - Support for semi-structured data (JSON, Parquet)
  - Integration with BI tools and ML platforms
  - Time-travel queries for audit trails

#### Message Queue: **Apache Kafka** or **AWS Kinesis**
- **Use Cases**: Event streaming, data pipeline, real-time processing
- **Rationale**:
  - Durable event log
  - Scalable stream processing
  - Integration with analytics and ML pipelines
  - Exactly-once semantics

### 1.2 Technology Decision Matrix

| Data Type | Database | Rationale |
|-----------|----------|-----------|
| User accounts, organizations | PostgreSQL | ACID, relations, auth |
| Campaign configs, ad creative | PostgreSQL | Structured, transactional |
| Follower profiles (structured) | PostgreSQL | Queryable, indexed |
| Social API raw responses | MongoDB | Flexible schema, nested data |
| Engagement metrics (time-series) | TimescaleDB | Optimized queries, retention |
| Behavioral event streams | TimescaleDB | Time-based analysis |
| AI personas, segments | PostgreSQL + MongoDB | Structured metadata + raw analysis |
| AI training datasets | MongoDB + S3 | Large unstructured data |
| Model predictions/scores | PostgreSQL | Queryable results |
| Search index (followers, content) | Elasticsearch | Full-text, fuzzy matching |
| Session data, API rate limits | Redis | Fast access, TTL |
| Computed aggregates | Redis | Caching expensive queries |
| Media files, exports | S3 | Large files, archival |
| Historical analytics | Snowflake/BigQuery | OLAP, BI reporting |

## 2. Core Data Models

### 2.1 Entity Relationship Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                     CORE OPERATIONAL DATABASE (PostgreSQL)          │
└─────────────────────────────────────────────────────────────────────┘

organizations                   users
┌──────────────┐               ┌──────────────┐
│ id (PK)      │───────────┬──>│ id (PK)      │
│ name         │           │   │ org_id (FK)  │
│ tier         │           │   │ email        │
│ settings     │           │   │ role         │
└──────────────┘           │   └──────────────┘
       │                   │           │
       │                   │           │ owns
       │                   │           ↓
       │                   │   ┌──────────────┐
       │ owns              │   │ api_keys     │
       │                   │   └──────────────┘
       ↓                   │
┌──────────────┐           │   ┌──────────────┐
│ social_accts │           └──>│ team_members │
│ id (PK)      │               └──────────────┘
│ org_id (FK)  │
│ platform     │───┐
│ credentials  │   │
└──────────────┘   │ linked to
       │           ↓
       │   ┌──────────────────┐
       │   │ followers        │
       │   │ id (PK)          │
       │   │ social_acct_id   │
       │   │ platform_id      │
       │   │ username         │
       │   │ profile_data     │
       │   │ enriched_data    │
       │   └──────────────────┘
       │           │
       │           │ grouped by
       │           ↓
       │   ┌──────────────────┐
       │   │ ai_segments      │
       │   │ id (PK)          │
       │   │ name             │
       │   │ criteria         │
       │   └──────────────────┘
       │           ↑
       │           │ contains
       │           │
       │   ┌──────────────────┐
       │   │ segment_members  │
       │   │ segment_id (FK)  │
       │   │ follower_id (FK) │
       │   │ match_score      │
       │   └──────────────────┘
       │
       │ targets
       ↓
┌──────────────────┐
│ campaigns        │──────┐
│ id (PK)          │      │
│ org_id (FK)      │      │ contains
│ name             │      │
│ objective        │      ↓
│ budget           │  ┌──────────────────┐
│ status           │  │ ad_groups        │
└──────────────────┘  │ id (PK)          │
       │              │ campaign_id (FK) │
       │              │ target_segments  │
       │ has          └──────────────────┘
       ↓                      │
┌──────────────────┐          │ contains
│ ad_creatives     │<─────────┘
│ id (PK)          │
│ campaign_id (FK) │
│ content          │
│ ai_generated     │
│ platform_specs   │
└──────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│              TIME-SERIES DATABASE (TimescaleDB)                     │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────────────┐     ┌──────────────────────┐
│ follower_engagement  │     │ campaign_metrics     │
│ time (PK)            │     │ time (PK)            │
│ follower_id          │     │ campaign_id          │
│ metric_type          │     │ ad_id                │
│ value                │     │ impressions          │
│ platform             │     │ clicks               │
└──────────────────────┘     │ conversions          │
                             │ spend                │
┌──────────────────────┐     └──────────────────────┘
│ behavioral_events    │
│ time (PK)            │     ┌──────────────────────┐
│ follower_id          │     │ ai_model_metrics     │
│ event_type           │     │ time (PK)            │
│ properties           │     │ model_id             │
│ session_id           │     │ accuracy             │
└──────────────────────┘     │ predictions          │
                             └──────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                 DOCUMENT STORE (MongoDB)                            │
└─────────────────────────────────────────────────────────────────────┘

social_platform_raw          ai_training_data
{                            {
  _id,                         _id,
  social_account_id,           dataset_name,
  platform,                    created_at,
  data_type,                   source_filters,
  raw_payload,                 records: [],
  fetched_at,                  labels: {},
  processed                    validation_split
}                            }

ai_persona_analysis          model_predictions
{                            {
  _id,                         _id,
  segment_id,                  follower_id,
  persona_profile,             model_version,
  behavioral_patterns,         predictions: {},
  interests: [],               confidence_scores,
  demographics,                predicted_at
  psychographics              }
}                            
```

## 3. Detailed Schema Design

### 3.1 PostgreSQL Schema (Transactional Data)

See: `schemas/postgresql/01_core_schema.sql`

### 3.2 TimescaleDB Schema (Time-Series Data)

See: `schemas/timescaledb/01_metrics_schema.sql`

### 3.3 MongoDB Schema (Document Store)

See: `schemas/mongodb/collections.js`

## 4. Indexing Strategy

### 4.1 PostgreSQL Indexes

#### Primary Indexes
- All primary keys automatically indexed (B-tree)
- Foreign keys indexed for join performance
- Unique constraints on natural keys (email, platform_user_id)

#### Secondary Indexes
```sql
-- User lookups
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_org_id ON users(organization_id);

-- Follower queries
CREATE INDEX idx_followers_platform_id ON followers(platform, platform_user_id);
CREATE INDEX idx_followers_social_account ON followers(social_account_id);
CREATE INDEX idx_followers_username ON followers(username); -- Prefix search
CREATE INDEX idx_followers_created ON followers(created_at DESC);

-- GIN indexes for JSONB
CREATE INDEX idx_followers_profile_data ON followers USING GIN(profile_data);
CREATE INDEX idx_followers_enriched_data ON followers USING GIN(enriched_data);

-- Full-text search
CREATE INDEX idx_followers_fts ON followers USING GIN(
  to_tsvector('english', username || ' ' || COALESCE(profile_data->>'bio', ''))
);

-- Segment queries
CREATE INDEX idx_segment_members_segment ON segment_members(segment_id);
CREATE INDEX idx_segment_members_follower ON segment_members(follower_id);
CREATE INDEX idx_segment_members_score ON segment_members(match_score DESC);

-- Campaign performance
CREATE INDEX idx_campaigns_org_status ON campaigns(organization_id, status);
CREATE INDEX idx_campaigns_dates ON campaigns(start_date, end_date);

-- Partial indexes for common queries
CREATE INDEX idx_active_campaigns ON campaigns(organization_id) 
  WHERE status = 'active';
CREATE INDEX idx_ai_generated_ads ON ad_creatives(campaign_id) 
  WHERE ai_generated = true;
```

#### Composite Indexes
```sql
-- Multi-column lookups
CREATE INDEX idx_followers_platform_account ON followers(platform, social_account_id);
CREATE INDEX idx_campaigns_org_status_dates ON campaigns(
  organization_id, status, start_date
);

-- Covering indexes for common queries
CREATE INDEX idx_segment_members_covering ON segment_members(
  segment_id, follower_id
) INCLUDE (match_score, assigned_at);
```

### 4.2 TimescaleDB Indexes

```sql
-- TimescaleDB automatically creates indexes on time columns
-- Additional indexes for common queries:

CREATE INDEX idx_follower_engagement_follower_time 
  ON follower_engagement(follower_id, time DESC);

CREATE INDEX idx_campaign_metrics_campaign_time 
  ON campaign_metrics(campaign_id, time DESC);

CREATE INDEX idx_behavioral_events_type_time 
  ON behavioral_events(event_type, time DESC);

-- Partial indexes for recent data
CREATE INDEX idx_recent_engagement 
  ON follower_engagement(follower_id, time DESC)
  WHERE time > NOW() - INTERVAL '30 days';
```

### 4.3 MongoDB Indexes

```javascript
// social_platform_raw collection
db.social_platform_raw.createIndex({ "social_account_id": 1, "fetched_at": -1 });
db.social_platform_raw.createIndex({ "platform": 1, "data_type": 1 });
db.social_platform_raw.createIndex({ "processed": 1 });

// TTL index for automatic cleanup
db.social_platform_raw.createIndex(
  { "fetched_at": 1 }, 
  { expireAfterSeconds: 7776000 } // 90 days
);

// ai_training_data collection
db.ai_training_data.createIndex({ "dataset_name": 1, "created_at": -1 });
db.ai_training_data.createIndex({ "source_filters.platform": 1 });

// ai_persona_analysis collection
db.ai_persona_analysis.createIndex({ "segment_id": 1 });
db.ai_persona_analysis.createIndex({ "persona_profile.interests": 1 });

// Text indexes for search
db.ai_persona_analysis.createIndex({
  "persona_profile.description": "text",
  "behavioral_patterns.common_topics": "text"
});
```

### 4.4 Elasticsearch Indexes

```json
{
  "followers_search": {
    "mappings": {
      "properties": {
        "follower_id": { "type": "keyword" },
        "username": { 
          "type": "text",
          "fields": {
            "keyword": { "type": "keyword" },
            "suggest": { "type": "completion" }
          }
        },
        "bio": { "type": "text" },
        "interests": { "type": "keyword" },
        "location": { "type": "geo_point" },
        "follower_count": { "type": "integer" },
        "engagement_rate": { "type": "float" },
        "last_active": { "type": "date" }
      }
    }
  }
}
```

## 5. Data Retention and Archival Policies

### 5.1 Hot Data (Active Storage)

| Data Type | Retention | Location | Rationale |
|-----------|-----------|----------|-----------|
| User accounts | Indefinite | PostgreSQL | Core business data |
| Active campaigns | Indefinite | PostgreSQL | Business critical |
| Follower profiles | Until unfollowed + 90 days | PostgreSQL | Active targeting |
| Real-time metrics (1-min) | 7 days | TimescaleDB | Operational monitoring |
| Hourly aggregates | 90 days | TimescaleDB | Tactical analysis |
| Daily aggregates | 2 years | TimescaleDB | Strategic planning |
| Raw social data | 90 days | MongoDB | API freshness |
| AI predictions | 180 days | PostgreSQL | Model performance |
| Session cache | 24 hours | Redis | Temporary data |

### 5.2 Warm Data (Compressed Storage)

| Data Type | Retention | Location | Action |
|-----------|-----------|----------|--------|
| Hourly metrics (90d+) | 1 year | TimescaleDB compressed | 10x compression |
| Daily metrics (2y+) | 5 years | TimescaleDB compressed | Archive old campaigns |
| Completed campaigns | 5 years | PostgreSQL | Move media to cold storage |
| Old follower profiles | 2 years | PostgreSQL partitioned | Partition by created_at |

### 5.3 Cold Data (Archival Storage)

| Data Type | Retention | Location | Format |
|-----------|-----------|----------|--------|
| Historical campaigns (5y+) | 7 years (legal) | S3 Glacier | Parquet |
| Audit logs | 7 years | S3 Standard-IA | JSON.gz |
| Old AI training data | 3 years | S3 Intelligent-Tiering | Parquet |
| Deleted user data | 30 days (recovery) | S3 (encrypted) | Encrypted JSON |

### 5.4 Automated Retention Implementation

#### TimescaleDB Retention Policy
```sql
-- Automatically drop raw metrics older than 7 days
SELECT add_retention_policy('follower_engagement', INTERVAL '7 days');

-- Keep hourly aggregates for 90 days
SELECT add_retention_policy('follower_engagement_hourly', INTERVAL '90 days');

-- Keep daily aggregates for 2 years
SELECT add_retention_policy('follower_engagement_daily', INTERVAL '730 days');
```

#### PostgreSQL Partitioning
```sql
-- Partition behavioral_events by month
CREATE TABLE behavioral_events (
  id BIGSERIAL,
  occurred_at TIMESTAMPTZ NOT NULL,
  ...
) PARTITION BY RANGE (occurred_at);

-- Automatic partition management (pg_partman)
SELECT create_parent('public.behavioral_events', 'occurred_at', 'native', 'monthly');
```

#### MongoDB TTL Indexes
```javascript
// Automatically delete documents older than 90 days
db.social_platform_raw.createIndex(
  { "fetched_at": 1 },
  { expireAfterSeconds: 7776000 }
);
```

## 6. Database Scaling Strategy

### 6.1 PostgreSQL Scaling

#### Vertical Scaling (Initial Phase)
- **Instance Size**: Start with 16 vCPU, 64GB RAM
- **Storage**: SSD-backed (io2 on AWS, Premium SSD on GCP)
- **IOPS**: Provisioned 10,000+ IOPS
- **Connection Pooling**: PgBouncer (2000+ connections → 100 server connections)

#### Read Replicas (10K+ users)
```
Primary (Write)
    ├── Replica 1 (Analytics queries)
    ├── Replica 2 (Dashboard reads)
    └── Replica 3 (API reads)
```

**Configuration**:
- Synchronous replication for critical reads
- Async replication for analytics
- Application-level read/write splitting

#### Horizontal Scaling via Sharding (100K+ users)

**Sharding Strategy**: Hash-based on `organization_id`

```
Shard 1: org_id % 4 = 0
Shard 2: org_id % 4 = 1
Shard 3: org_id % 4 = 2
Shard 4: org_id % 4 = 3
```

**Implementation Options**:
1. **Citus** (PostgreSQL extension for sharding)
2. **Manual sharding** via application routing layer
3. **Vitess** (horizontal scaling middleware)

**Considerations**:
- Global tables replicated to all shards (users, organizations)
- Cross-shard queries avoided in application logic
- Distributed transactions minimized

### 6.2 TimescaleDB Scaling

#### Multi-Node Setup
```
Access Node (Query Router)
    ├── Data Node 1 (Shards 1-3)
    ├── Data Node 2 (Shards 4-6)
    └── Data Node 3 (Shards 7-9)
```

**Features**:
- Automatic query parallelization
- Distributed continuous aggregates
- Native compression on data nodes

#### Tiered Storage
- Hot data (7 days): NVMe SSD
- Warm data (90 days): Standard SSD
- Cold data (2 years): HDD with compression

### 6.3 MongoDB Scaling

#### Replica Set (Initial)
```
Primary
    ├── Secondary 1 (Read preference)
    └── Secondary 2 (Backup)
```

#### Sharded Cluster (1M+ documents)
```
mongos (Router)
    ├── Config Servers (3 replicas)
    ├── Shard 1: social_account_id hash [0-33%)
    ├── Shard 2: social_account_id hash [33%-66%)
    └── Shard 3: social_account_id hash [66%-100%)
```

**Shard Key**: `{ social_account_id: "hashed" }`
- Ensures even distribution
- Allows targeted queries by account
- Avoids hot spots

### 6.4 Redis Scaling

#### Redis Cluster
```
Master 1 (Slots 0-5460)      + Replica 1
Master 2 (Slots 5461-10922)  + Replica 2
Master 3 (Slots 10923-16383) + Replica 3
```

#### Data Segregation
- **Cluster 1**: Session data, rate limits (low latency)
- **Cluster 2**: Computed aggregates, cache (high throughput)
- **Cluster 3**: Pub/Sub, real-time events (dedicated resources)

### 6.5 Elasticsearch Scaling

#### Cluster Architecture
```
3 Master Nodes (cluster management)
6 Data Nodes (hot tier, SSD)
3 Data Nodes (warm tier, HDD)
2 Coordinating Nodes (query routing)
```

**Index Management**:
- Hot indices: 7 days (SSD, 2 shards, 1 replica)
- Warm indices: 90 days (HDD, 1 shard, 1 replica)
- Cold indices: Frozen for search (S3 snapshot)

## 7. Data Warehouse Design

### 7.1 Architecture: Lambda Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        SPEED LAYER                          │
│  (Real-time: Kafka → Flink → TimescaleDB → Dashboard)      │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                       BATCH LAYER                           │
│  (Nightly: ETL → Data Warehouse → BI Tools)                │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                      SERVING LAYER                          │
│         (Materialized Views, OLAP Cubes, APIs)              │
└─────────────────────────────────────────────────────────────┘
```

### 7.2 Star Schema Design (Snowflake/BigQuery)

```
                    ┌─────────────────┐
                    │  fact_campaigns │
                    │──────────────────│
                    │ campaign_key PK │
         ┌──────────│ date_key FK     │──────────┐
         │          │ org_key FK      │          │
         │    ┌─────│ platform_key FK │─────┐    │
         │    │     │ segment_key FK  │     │    │
         │    │     │ impressions     │     │    │
         │    │     │ clicks          │     │    │
         │    │     │ conversions     │     │    │
         │    │     │ spend           │     │    │
         │    │     │ revenue         │     │    │
         │    │     └─────────────────┘     │    │
         ↓    ↓                             ↓    ↓
┌────────────┐ ┌────────────┐    ┌────────────┐ ┌────────────┐
│ dim_date   │ │ dim_org    │    │ dim_platform│ │dim_segment │
│────────────│ │────────────│    │────────────│ │────────────│
│ date_key PK│ │ org_key PK │    │platform_key│ │segment_key │
│ date       │ │ org_id     │    │ platform   │ │ segment_id │
│ year       │ │ name       │    │ name       │ │ name       │
│ quarter    │ │ tier       │    │ category   │ │ size       │
│ month      │ │ industry   │    └────────────┘ │ ai_method  │
│ week       │ │ region     │                   └────────────┘
│ day        │ └────────────┘
└────────────┘

                  ┌──────────────────┐
                  │ fact_engagement  │
                  │──────────────────│
                  │ engagement_key PK│
       ┌──────────│ timestamp        │──────────┐
       │          │ follower_key FK  │          │
       │     ┌────│ post_key FK      │────┐     │
       │     │    │ metric_type      │    │     │
       │     │    │ metric_value     │    │     │
       │     │    └──────────────────┘    │     │
       ↓     ↓                            ↓     ↓
┌──────────┐ ┌──────────────┐    ┌──────────┐ ┌──────────┐
│dim_time  │ │dim_follower  │    │ dim_post │ │dim_metric│
│──────────│ │──────────────│    │──────────│ │──────────│
│ time_key │ │follower_key  │    │ post_key │ │metric_key│
│ hour     │ │ follower_id  │    │ post_id  │ │ type     │
│ minute   │ │ platform     │    │ type     │ │ category │
│ second   │ │ segment      │    │ reach    │ │ unit     │
└──────────┘ │ demographics │    └──────────┘ └──────────┘
             │ interests[]  │
             └──────────────┘
```

### 7.3 ETL Pipeline

```python
# Nightly ETL Process (dbt, Airflow, or Prefect)

1. Extract (2:00 AM UTC)
   - PostgreSQL → Parquet (Incremental)
   - TimescaleDB → Parquet (Daily aggregates)
   - MongoDB → Parquet (Processed documents)

2. Transform (3:00 AM UTC)
   - Clean and normalize data
   - Apply business logic
   - Calculate derived metrics
   - Build dimension tables (SCD Type 2)
   - Aggregate fact tables

3. Load (4:00 AM UTC)
   - Merge into Data Warehouse
   - Update materialized views
   - Refresh BI tool caches
   - Send completion notifications

4. Validate (5:00 AM UTC)
   - Row counts
   - Data quality checks
   - Reconciliation reports
```

### 7.4 Data Warehouse Schema (Snowflake DDL)

See: `schemas/snowflake/warehouse_schema.sql`

## 8. Cache Layer Design

### 8.1 Redis Architecture

#### Cache Hierarchy
```
L1: Application Memory (User sessions, config)
     ↓ (miss)
L2: Redis Cluster (Hot data, computed results)
     ↓ (miss)
L3: Database (Source of truth)
```

#### Redis Data Structures

##### 1. String/Hash: User Sessions
```redis
# Key pattern: session:{session_id}
# TTL: 24 hours
session:abc123 → {
  user_id: 456,
  org_id: 789,
  permissions: ["read", "write"],
  last_active: 1699999999
}
```

##### 2. Sorted Set: Rate Limiting
```redis
# Key pattern: ratelimit:{user_id}:{endpoint}
# Track API calls with timestamps
ZADD ratelimit:456:/api/followers 1699999999 request_1
ZCOUNT ratelimit:456:/api/followers (NOW-3600) +inf  # Count last hour
```

##### 3. Hash: Follower Counts (Denormalized)
```redis
# Key pattern: stats:account:{social_account_id}
# TTL: 1 hour
stats:account:123 → {
  total_followers: 10000,
  new_followers_today: 45,
  avg_engagement: 3.2,
  last_updated: 1699999999
}
```

##### 4. Sorted Set: Leaderboards
```redis
# Top engaged followers
ZADD leaderboard:engagement:{account_id} 95.5 follower_1
ZADD leaderboard:engagement:{account_id} 87.2 follower_2
ZREVRANGE leaderboard:engagement:{account_id} 0 9  # Top 10
```

##### 5. Stream: Real-time Events
```redis
# Event stream for websocket notifications
XADD events:campaign:123 * type "impression" count 1 timestamp 1699999999
XREAD COUNT 100 STREAMS events:campaign:123 0-0  # Read events
```

##### 6. RedisJSON: Complex Objects
```redis
# Cached AI persona
JSON.SET persona:seg_456 $ '{
  "segment_id": 456,
  "persona_name": "Tech Enthusiasts",
  "demographics": {"age_range": "25-34", "interests": ["AI", "Tech"]},
  "last_computed": 1699999999
}'
```

##### 7. RedisTimeSeries: Short-term Metrics
```redis
# Last 1 hour of campaign performance
TS.CREATE metrics:campaign:123:impressions RETENTION 3600
TS.ADD metrics:campaign:123:impressions * 150
```

### 8.2 Cache Invalidation Strategy

#### Time-based (TTL)
```python
# Short TTL for frequently changing data
redis.setex("stats:account:123", 300, json.dumps(stats))  # 5 min

# Long TTL for stable data
redis.setex("config:org:456", 3600, json.dumps(config))  # 1 hour
```

#### Event-based Invalidation
```python
# Delete cache on data change
def update_follower(follower_id, data):
    db.update_follower(follower_id, data)
    redis.delete(f"follower:{follower_id}")
    redis.delete(f"stats:account:{data['social_account_id']}")
```

#### Cache-Aside Pattern
```python
def get_follower_stats(account_id):
    cache_key = f"stats:account:{account_id}"
    
    # Try cache first
    cached = redis.get(cache_key)
    if cached:
        return json.loads(cached)
    
    # Cache miss: compute and store
    stats = db.compute_follower_stats(account_id)
    redis.setex(cache_key, 300, json.dumps(stats))
    return stats
```

#### Write-Through Pattern
```python
def update_campaign_metrics(campaign_id, metrics):
    # Write to database
    db.save_metrics(campaign_id, metrics)
    
    # Write to cache
    cache_key = f"metrics:campaign:{campaign_id}"
    redis.setex(cache_key, 600, json.dumps(metrics))
```

### 8.3 Cache Warming

```python
# Pre-populate cache for active campaigns
def warm_campaign_cache():
    active_campaigns = db.get_active_campaigns()
    for campaign in active_campaigns:
        metrics = db.get_campaign_metrics(campaign.id)
        redis.setex(f"metrics:campaign:{campaign.id}", 600, 
                   json.dumps(metrics))
```

## 9. Time-Series Data Handling

### 9.1 TimescaleDB Hypertables

```sql
-- Convert regular table to hypertable
SELECT create_hypertable('follower_engagement', 'time', 
                        chunk_time_interval => INTERVAL '1 day');

-- Automatically partition by time
-- Chunks: 2024-01-01, 2024-01-02, ..., 2024-01-31
```

### 9.2 Continuous Aggregates (Real-time Materialized Views)

```sql
-- Hourly aggregates (updated automatically)
CREATE MATERIALIZED VIEW follower_engagement_hourly
WITH (timescaledb.continuous) AS
SELECT 
  time_bucket('1 hour', time) AS hour,
  follower_id,
  metric_type,
  AVG(value) as avg_value,
  MAX(value) as max_value,
  COUNT(*) as count
FROM follower_engagement
GROUP BY hour, follower_id, metric_type;

-- Refresh policy (update every 30 minutes)
SELECT add_continuous_aggregate_policy('follower_engagement_hourly',
  start_offset => INTERVAL '2 hours',
  end_offset => INTERVAL '30 minutes',
  schedule_interval => INTERVAL '30 minutes');
```

### 9.3 Compression

```sql
-- Enable compression (10-20x size reduction)
ALTER TABLE follower_engagement SET (
  timescaledb.compress,
  timescaledb.compress_segmentby = 'follower_id, metric_type',
  timescaledb.compress_orderby = 'time DESC'
);

-- Auto-compress chunks older than 7 days
SELECT add_compression_policy('follower_engagement', INTERVAL '7 days');
```

### 9.4 Downsampling Strategy

```sql
-- Keep raw data for 7 days
-- Keep 1-min aggregates for 30 days
-- Keep hourly aggregates for 90 days
-- Keep daily aggregates for 2 years

-- Example: Downsample to daily after 90 days
CREATE MATERIALIZED VIEW follower_engagement_daily
WITH (timescaledb.continuous) AS
SELECT 
  time_bucket('1 day', time) AS day,
  follower_id,
  metric_type,
  AVG(value) as avg_value,
  MAX(value) as max_value,
  MIN(value) as min_value,
  SUM(value) as total_value
FROM follower_engagement
GROUP BY day, follower_id, metric_type;
```

### 9.5 Query Optimization

```sql
-- Time-based partitioning enables fast queries
-- Bad: Full table scan
SELECT * FROM follower_engagement WHERE follower_id = 123;

-- Good: Partition pruning
SELECT * FROM follower_engagement 
WHERE time > NOW() - INTERVAL '7 days' 
  AND follower_id = 123;

-- Best: Use continuous aggregates
SELECT * FROM follower_engagement_hourly
WHERE hour > NOW() - INTERVAL '30 days'
  AND follower_id = 123;
```

## 10. Privacy and Data Anonymization Strategy

### 10.1 Data Classification

| Category | Examples | Protection Level |
|----------|----------|------------------|
| **PII** | Email, phone, real name | Encrypted at rest, masked in logs |
| **Quasi-identifiers** | Location, age, job title | Aggregated in analytics |
| **Sensitive** | Political affiliation, religion | Opt-in only, strict access |
| **Public** | Username, follower count | Standard protection |
| **Internal** | AI model scores, segments | Access control |

### 10.2 Encryption Strategy

#### At-Rest Encryption
- **PostgreSQL**: Transparent Data Encryption (TDE) or AWS RDS encryption
- **MongoDB**: Field-level encryption for PII fields
- **S3**: Server-side encryption (SSE-KMS)
- **Redis**: Encryption at rest for persistent data

#### In-Transit Encryption
- TLS 1.3 for all database connections
- VPN/PrivateLink for cross-region replication
- End-to-end encryption for API data transfer

#### Application-Level Encryption (Envelope Encryption)

```sql
-- Store encrypted data with key ID reference
CREATE TABLE followers (
  id BIGSERIAL PRIMARY KEY,
  username VARCHAR(255),
  email_encrypted BYTEA,  -- Encrypted with DEK
  encryption_key_id VARCHAR(50),  -- Reference to KMS key
  ...
);
```

### 10.3 Data Anonymization Techniques

#### Pseudonymization
```sql
-- Replace PII with pseudonyms (reversible with key)
CREATE TABLE follower_analytics (
  follower_hash VARCHAR(64),  -- SHA256(follower_id + salt)
  engagement_score FLOAT,
  ...
);
```

#### Aggregation
```sql
-- Prevent re-identification via aggregation (k-anonymity)
SELECT 
  age_bucket,  -- "25-34" instead of exact age
  location_city,  -- City instead of precise coordinates
  COUNT(*) as followers
FROM followers
GROUP BY age_bucket, location_city
HAVING COUNT(*) >= 5;  -- Ensure minimum group size
```

#### Differential Privacy
```python
# Add statistical noise to prevent individual identification
def get_segment_stats(segment_id, epsilon=1.0):
    true_count = db.count_followers(segment_id)
    noise = laplace_noise(scale=1/epsilon)  # Laplace mechanism
    return max(0, true_count + noise)
```

#### Data Masking (Non-production Environments)
```sql
-- Create anonymized copy for dev/staging
CREATE TABLE followers_dev AS
SELECT 
  id,
  'user_' || id as username,  -- Synthetic username
  MD5(RANDOM()::text) || '@example.com' as email,  -- Fake email
  FLOOR(RANDOM() * 100000) as follower_count,  -- Randomized counts
  ...
FROM followers;
```

### 10.4 Access Control

#### Row-Level Security (RLS)
```sql
-- Users can only access their organization's data
ALTER TABLE followers ENABLE ROW LEVEL SECURITY;

CREATE POLICY org_isolation ON followers
  USING (social_account_id IN (
    SELECT id FROM social_accounts 
    WHERE organization_id = current_setting('app.current_org_id')::int
  ));
```

#### Column-Level Security
```sql
-- Restrict access to sensitive fields
GRANT SELECT ON followers TO analyst_role;
REVOKE SELECT (email_encrypted, phone_encrypted) ON followers FROM analyst_role;
```

#### Audit Logging
```sql
-- Track all access to PII
CREATE TABLE audit_log (
  id BIGSERIAL PRIMARY KEY,
  user_id INT,
  action VARCHAR(50),  -- SELECT, UPDATE, DELETE
  table_name VARCHAR(100),
  record_id BIGINT,
  accessed_at TIMESTAMPTZ DEFAULT NOW(),
  ip_address INET
);

-- Trigger on sensitive tables
CREATE TRIGGER audit_follower_access
  AFTER SELECT ON followers
  FOR EACH STATEMENT
  EXECUTE FUNCTION log_access();
```

### 10.5 Data Minimization

#### Collection
- Only collect data necessary for features
- Prompt for consent before collecting sensitive data
- Provide granular opt-in/opt-out controls

#### Retention
- Delete raw social API data after processing (90 days)
- Aggregate old data, delete raw records
- Automated deletion of inactive accounts

#### Anonymization Pipeline
```sql
-- Anonymize data older than 2 years
UPDATE followers SET
  email = NULL,
  phone = NULL,
  ip_address = NULL
WHERE last_active_at < NOW() - INTERVAL '2 years';
```

### 10.6 Right to Deletion (GDPR/CCPA Compliance)

```sql
-- Soft delete with retention period
CREATE TABLE deleted_users (
  user_id INT PRIMARY KEY,
  deleted_at TIMESTAMPTZ DEFAULT NOW(),
  data_backup JSONB,  -- Encrypted backup for 30 days
  permanent_deletion_at TIMESTAMPTZ GENERATED ALWAYS AS 
    (deleted_at + INTERVAL '30 days') STORED
);

-- Hard delete after grace period
DELETE FROM deleted_users WHERE permanent_deletion_at < NOW();
```

### 10.7 Privacy by Design Checklist

- [ ] Encrypt PII at rest and in transit
- [ ] Implement pseudonymization for analytics
- [ ] Apply k-anonymity (min group size = 5) for public reports
- [ ] Enable row-level security per organization
- [ ] Log all access to sensitive data
- [ ] Automated data retention policies
- [ ] User consent management
- [ ] Data export functionality (GDPR right to access)
- [ ] Deletion workflow (GDPR right to be forgotten)
- [ ] Regular privacy impact assessments

---

## Summary

This architecture provides:

✅ **Scalability**: Handles millions of followers, billions of events
✅ **Performance**: Sub-second queries via indexing, caching, time-series optimization
✅ **Reliability**: Multi-region replication, automated backups, point-in-time recovery
✅ **Flexibility**: Polyglot persistence for optimal data storage
✅ **Compliance**: GDPR/CCPA-ready with encryption, anonymization, and audit trails
✅ **Cost Efficiency**: Tiered storage, compression, automated archival

**Next Steps**:
1. Review and approve schema designs
2. Set up development environment with Docker Compose
3. Implement database migrations
4. Build data pipeline POC
5. Load testing and optimization

