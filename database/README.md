# Database Architecture for AI-Powered Follower Intelligence System

## Overview

This directory contains the complete database architecture, schemas, and deployment configurations for the social intelligence platform. The system uses a polyglot persistence approach with multiple specialized databases optimized for different workloads.

## Architecture Highlights

- **PostgreSQL**: Core transactional data (users, campaigns, followers)
- **TimescaleDB**: Time-series metrics (engagement, performance)
- **MongoDB**: Flexible document storage (raw API data, AI personas)
- **Redis**: Distributed cache and real-time features
- **Elasticsearch**: Full-text search
- **Snowflake/BigQuery**: Data warehouse for analytics

## Directory Structure

```
database/
├── docs/
│   ├── DATABASE_ARCHITECTURE.md    # Complete architecture guide
│   ├── ER_DIAGRAMS.md              # Entity-relationship diagrams
│   └── CACHE_STRATEGY.md           # Redis caching strategy
├── schemas/
│   ├── postgresql/
│   │   └── 01_core_schema.sql      # Core transactional tables
│   ├── timescaledb/
│   │   └── 01_metrics_schema.sql   # Time-series hypertables
│   ├── mongodb/
│   │   └── collections.js          # Document collections
│   └── snowflake/
│       └── warehouse_schema.sql    # Data warehouse schema
├── migrations/                      # Database migration scripts
├── diagrams/                        # Visual diagrams
├── docker-compose.yml              # Local development environment
└── README.md                       # This file
```

## Quick Start (Local Development)

### 1. Prerequisites

- Docker & Docker Compose
- 8GB+ RAM available
- 20GB+ disk space

### 2. Start All Services

```bash
cd database
docker-compose up -d
```

This will start:
- PostgreSQL (port 5432)
- TimescaleDB (port 5433)
- MongoDB (port 27017)
- Redis (port 6379)
- Elasticsearch (port 9200)
- MinIO/S3 (port 9000)
- Management UIs (see below)

### 3. Access Management UIs

| Service | URL | Credentials |
|---------|-----|-------------|
| pgAdmin | http://localhost:5050 | admin@example.com / admin |
| Mongo Express | http://localhost:8082 | admin / admin |
| Redis Commander | http://localhost:8081 | - |
| Kibana | http://localhost:5601 | - |
| MinIO Console | http://localhost:9001 | minioadmin / minioadmin |
| Grafana | http://localhost:3000 | admin / admin |

### 4. Initialize Schemas

```bash
# PostgreSQL
docker exec -i social_intelligence_postgres \
  psql -U dev_user -d social_intelligence \
  < schemas/postgresql/01_core_schema.sql

# TimescaleDB
docker exec -i social_intelligence_timescaledb \
  psql -U dev_user -d social_intelligence_metrics \
  < schemas/timescaledb/01_metrics_schema.sql

# MongoDB
docker exec -i social_intelligence_mongodb \
  mongosh -u dev_user -p dev_password \
  --authenticationDatabase admin \
  social_intelligence < schemas/mongodb/collections.js
```

### 5. Verify Installation

```bash
# Check all services are healthy
docker-compose ps

# Test PostgreSQL connection
docker exec social_intelligence_postgres \
  psql -U dev_user -d social_intelligence -c "SELECT version();"

# Test Redis
docker exec social_intelligence_redis redis-cli ping

# Test MongoDB
docker exec social_intelligence_mongodb \
  mongosh --eval "db.adminCommand('ping')"
```

## Database Details

### PostgreSQL (Core Database)

**Connection String:**
```
postgresql://dev_user:dev_password@localhost:5432/social_intelligence
```

**Key Tables:**
- `organizations`: Multi-tenant organizations
- `users`: User accounts and authentication
- `social_accounts`: Connected social media accounts
- `followers`: Follower profiles and enriched data
- `ai_segments`: AI-generated audience segments
- `campaigns`: Ad campaigns and configurations
- `ad_creatives`: Ad creative content (AI-generated)

**Features:**
- Row-level security for multi-tenancy
- JSONB columns for flexible schemas
- Full-text search with GIN indexes
- PostGIS for geo-targeting
- Automatic timestamp triggers

### TimescaleDB (Time-Series Metrics)

**Connection String:**
```
postgresql://dev_user:dev_password@localhost:5433/social_intelligence_metrics
```

**Key Hypertables:**
- `follower_engagement`: Engagement metrics per follower
- `campaign_metrics`: Campaign performance data
- `behavioral_events`: User behavioral events
- `ai_model_metrics`: AI model performance tracking

**Features:**
- Automatic time-based partitioning (1-day chunks)
- Continuous aggregates (hourly, daily rollups)
- Automatic compression (10-20x reduction after 7 days)
- Retention policies (auto-delete old data)

### MongoDB (Document Store)

**Connection String:**
```
mongodb://dev_user:dev_password@localhost:27017/social_intelligence
```

**Key Collections:**
- `social_platform_raw`: Raw API responses from social platforms
- `ai_training_data`: ML training datasets
- `ai_persona_analysis`: Detailed persona profiles
- `ai_generated_content`: AI-generated ad content history
- `ab_test_experiments`: A/B test configurations and results

**Features:**
- Flexible schema for varying social platform APIs
- TTL indexes for automatic data expiration
- Text search indexes
- Change streams for real-time processing

### Redis (Cache Layer)

**Connection String:**
```
redis://localhost:6379
```

**Key Patterns:**
- `session:{id}`: User sessions (Hash, 24h TTL)
- `ratelimit:{user}:{endpoint}`: Rate limiting (Sorted Set)
- `stats:account:{id}`: Cached account stats (Hash, 5min TTL)
- `leaderboard:{type}:{scope}`: Engagement leaderboards (Sorted Set)
- `events:{type}:{id}`: Real-time event streams (Stream)

**Features:**
- LRU eviction policy
- AOF + RDB persistence
- Pub/Sub for real-time notifications
- RedisJSON for complex objects
- RedisTimeSeries for short-term metrics

## Scaling Strategy

### Phase 1: Single Region (0-10K users)

```
┌─────────────────────────────────────────────┐
│  Single PostgreSQL Instance                 │
│  + Read Replica for Analytics               │
│  + Redis (single instance)                  │
│  + MongoDB (replica set)                    │
└─────────────────────────────────────────────┘
```

### Phase 2: Vertical + Horizontal Scaling (10K-100K users)

```
┌─────────────────────────────────────────────┐
│  PostgreSQL (Citus or Manual Sharding)      │
│  + 3 Read Replicas                          │
│  + Redis Cluster (3 masters + 3 replicas)  │
│  + MongoDB Sharded Cluster                  │
│  + TimescaleDB Multi-node                   │
└─────────────────────────────────────────────┘
```

### Phase 3: Multi-Region (100K+ users)

```
┌─────────────────────────────────────────────┐
│  Region 1 (US-East)                         │
│  ├─ Full Database Stack                     │
│  └─ Primary for US customers                │
│                                              │
│  Region 2 (EU-West)                         │
│  ├─ Full Database Stack                     │
│  └─ Primary for EU customers (GDPR)         │
│                                              │
│  Data Warehouse (Global)                    │
│  └─ Snowflake/BigQuery for Analytics        │
└─────────────────────────────────────────────┘
```

## Performance Optimization

### Indexing Strategy

**PostgreSQL:**
- B-tree indexes on foreign keys and frequently filtered columns
- GIN indexes on JSONB columns
- Full-text search indexes with pg_trgm
- Partial indexes for active/recent data

**TimescaleDB:**
- Automatic time-based indexing
- Composite indexes on (entity_id, time)
- Covering indexes for common queries

**MongoDB:**
- Compound indexes on query patterns
- Text indexes for search
- TTL indexes for auto-expiration

### Caching Strategy

**3-Tier Cache:**
1. **Application Memory** (5-15 min): Config, feature flags
2. **Redis** (5 min - 24h): Hot data, computed results
3. **Database** (Infinite): Source of truth

**Cache Invalidation:**
- Time-based (TTL) for most data
- Event-based for critical updates
- Tag-based for bulk invalidation

### Query Optimization

**Best Practices:**
- Always filter time-series data by time range
- Use continuous aggregates instead of raw data
- Leverage partition pruning in PostgreSQL
- Use connection pooling (PgBouncer, Mongo driver pools)
- Monitor slow queries and optimize indexes

## Data Retention

| Data Type | Hot Storage | Warm Storage | Cold Storage |
|-----------|-------------|--------------|--------------|
| User accounts | Indefinite | - | - |
| Follower profiles | 90 days | 2 years | Archived |
| Raw metrics | 7 days | 90 days (compressed) | 2 years |
| Aggregated metrics | 90 days | 2 years | 5 years |
| Raw social data | 90 days | - | Deleted |
| Campaign data | Indefinite | - | 7 years (legal) |

## Security

### Encryption

- **At Rest**: Enabled on all databases
- **In Transit**: TLS 1.3 for all connections
- **Application-Level**: PII encrypted with KMS keys

### Access Control

- **Row-Level Security**: Enforced in PostgreSQL
- **Database Users**: Separate read/write users
- **API Keys**: Hashed and never stored in plain text
- **Audit Logging**: All sensitive data access logged

### Compliance

- **GDPR**: Right to deletion, data export, encryption
- **CCPA**: Data minimization, opt-out mechanisms
- **SOC 2**: Audit trails, access controls

## Monitoring

### Key Metrics

**Database Health:**
- Connection pool utilization
- Query latency (p50, p95, p99)
- Slow query counts
- Replication lag
- Disk usage and growth rate

**Cache Performance:**
- Cache hit rate (target: >85%)
- Eviction rate
- Memory usage
- Connection counts

**Application Metrics:**
- API response times
- Error rates
- Throughput (requests/sec)

### Alerting Thresholds

```yaml
Critical:
  - Database connection pool > 90%
  - Replication lag > 10 seconds
  - Disk usage > 85%
  - Cache hit rate < 70%

Warning:
  - Slow queries > 2 seconds
  - Connection pool > 70%
  - Disk usage > 70%
  - Cache memory > 80%
```

## Backup & Disaster Recovery

### Backup Strategy

**PostgreSQL:**
- Continuous WAL archiving
- Daily full backups (retained 30 days)
- Point-in-time recovery (PITR) capability

**MongoDB:**
- Daily snapshots (retained 7 days)
- Oplog replay for recent data

**Redis:**
- AOF persistence (every second)
- RDB snapshots (hourly)
- Backup to S3 daily

**TimescaleDB:**
- Continuous aggregates provide redundancy
- Daily backups of compressed chunks

### Disaster Recovery

**RTO (Recovery Time Objective):** 1 hour
**RPO (Recovery Point Objective):** 15 minutes

**DR Procedures:**
1. Promote read replica to primary (PostgreSQL)
2. Switch to standby region (multi-region setup)
3. Restore from backup (worst case)

## Migration & Versioning

### Schema Migrations

We use **Alembic** (Python) or **Flyway** (Java) for schema versioning.

```bash
# Run migrations
alembic upgrade head

# Rollback
alembic downgrade -1
```

### Zero-Downtime Migrations

1. **Additive Changes First**: Add new columns/tables without removing old
2. **Deploy Application**: Update app to use new schema
3. **Remove Old Schema**: After confirming stability

## Cost Optimization

### Development

- Use Docker Compose (local, free)
- Shared database instances
- Minimal retention periods

### Production (Estimated)

**Monthly Costs (10K users, 1M followers tracked):**
- PostgreSQL (AWS RDS): $200-500
- TimescaleDB (Timescale Cloud): $150-300
- MongoDB Atlas (M30): $250-400
- Redis (ElastiCache): $100-200
- Elasticsearch (AWS): $150-300
- S3 Storage: $50-100
- Data Transfer: $100-200
- **Total: $1,000-2,000/month**

**Optimization Tips:**
- Use Reserved Instances (30-50% savings)
- Enable compression (10-20x storage reduction)
- Implement aggressive caching
- Archive old data to cheaper storage tiers

## Troubleshooting

### Common Issues

**High Database Load:**
```sql
-- Find slow queries (PostgreSQL)
SELECT query, calls, mean_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;

-- Check locks
SELECT * FROM pg_locks WHERE NOT granted;
```

**Cache Misses:**
```redis
# Check hit rate
INFO stats

# Find memory hogs
MEMORY USAGE key_pattern
```

**Replication Lag:**
```sql
-- Check lag (PostgreSQL)
SELECT NOW() - pg_last_xact_replay_timestamp() AS lag;
```

## Support

For questions or issues:
- **Documentation**: See `docs/DATABASE_ARCHITECTURE.md`
- **Diagrams**: See `docs/ER_DIAGRAMS.md`
- **Cache Strategy**: See `docs/CACHE_STRATEGY.md`

## License

[Your License Here]

## Contributors

[Your Team]

---

**Last Updated:** 2024-11-17
**Version:** 1.0

