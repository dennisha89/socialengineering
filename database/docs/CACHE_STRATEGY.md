# Redis Cache Layer Strategy

## Overview

This document outlines the caching strategy for the AI-powered follower intelligence system using Redis as the primary cache layer.

## Cache Architecture

### Multi-Tier Caching

```
┌─────────────────────────────────────────────────────────────┐
│                    CACHE HIERARCHY                          │
└─────────────────────────────────────────────────────────────┘

Level 1: Application Memory (In-Process)
├─ User session data
├─ Configuration
├─ Feature flags
└─ TTL: 5-15 minutes

      ↓ Cache miss

Level 2: Redis (Distributed)
├─ Hot data (frequently accessed)
├─ Computed aggregates
├─ Rate limiting counters
└─ TTL: 5 minutes - 24 hours

      ↓ Cache miss

Level 3: Database (Source of Truth)
├─ PostgreSQL (structured data)
├─ TimescaleDB (metrics)
├─ MongoDB (documents)
└─ Always consistent
```

## Redis Cluster Configuration

### Cluster Setup

```
Production Cluster (6 nodes):

Master Nodes:
├─ redis-master-1 (slots 0-5460)      → redis-replica-1
├─ redis-master-2 (slots 5461-10922)  → redis-replica-2
└─ redis-master-3 (slots 10923-16383) → redis-replica-3

Configuration:
- Memory: 16GB per node
- Persistence: AOF + RDB
- Maxmemory policy: allkeys-lru
- Cluster enabled: yes
```

### Data Segregation by Cluster

```
Cluster 1 (Low Latency):
- Sessions (user:{id}:session)
- API rate limits (ratelimit:{key})
- Real-time counters
- Memory: 16GB
- Eviction: volatile-lru

Cluster 2 (High Throughput):
- Computed aggregates (stats:*)
- Cached queries (cache:*)
- Leaderboards (leaderboard:*)
- Memory: 32GB
- Eviction: allkeys-lru

Cluster 3 (Pub/Sub):
- Real-time events (events:*)
- Websocket notifications
- Job queues
- Memory: 8GB
- Persistence: disabled
```

## Data Structures & Use Cases

### 1. Strings / Hashes: User Sessions

```redis
# Key pattern: session:{session_id}
# Data structure: Hash
# TTL: 24 hours

HSET session:abc123xyz \
  user_id 456 \
  organization_id 789 \
  email "user@example.com" \
  role "admin" \
  permissions '["read","write","delete"]' \
  last_active 1699999999 \
  ip_address "192.168.1.1"

EXPIRE session:abc123xyz 86400

# Get session
HGETALL session:abc123xyz

# Update last active
HSET session:abc123xyz last_active 1700000000
```

### 2. Sorted Sets: Rate Limiting

```redis
# Key pattern: ratelimit:{user_id}:{endpoint}
# Data structure: Sorted Set
# TTL: 1 hour

# Add request with timestamp as score
ZADD ratelimit:456:/api/followers 1699999999.123 "request_uuid_1"
ZADD ratelimit:456:/api/followers 1700000000.456 "request_uuid_2"

# Count requests in last 60 seconds
ZCOUNT ratelimit:456:/api/followers \
  (NOW-60) +inf

# Remove old requests (older than 1 hour)
ZREMRANGEBYSCORE ratelimit:456:/api/followers \
  -inf (NOW-3600)

# Set expiry
EXPIRE ratelimit:456:/api/followers 3600
```

### 3. Hashes: Account Statistics

```redis
# Key pattern: stats:account:{social_account_id}
# Data structure: Hash
# TTL: 5 minutes

HSET stats:account:123 \
  total_followers 10000 \
  new_followers_today 45 \
  new_followers_week 320 \
  avg_engagement_rate 3.2 \
  top_post_id "post_xyz" \
  last_updated 1699999999

EXPIRE stats:account:123 300

# Get all stats
HGETALL stats:account:123

# Get specific stat
HGET stats:account:123 total_followers

# Increment counter
HINCRBY stats:account:123 total_followers 1
```

### 4. Sorted Sets: Leaderboards

```redis
# Key pattern: leaderboard:{type}:{scope}
# Data structure: Sorted Set
# No TTL (persistent)

# Top engaged followers
ZADD leaderboard:engagement:account_123 95.5 "follower_1"
ZADD leaderboard:engagement:account_123 87.2 "follower_2"
ZADD leaderboard:engagement:account_123 82.1 "follower_3"

# Get top 10
ZREVRANGE leaderboard:engagement:account_123 0 9 WITHSCORES

# Get rank for a specific follower
ZREVRANK leaderboard:engagement:account_123 "follower_1"

# Get score
ZSCORE leaderboard:engagement:account_123 "follower_1"

# Increment score
ZINCRBY leaderboard:engagement:account_123 2.5 "follower_1"
```

### 5. Streams: Real-time Events

```redis
# Key pattern: events:{resource_type}:{resource_id}
# Data structure: Stream
# TTL: 24 hours (MAXLEN trim)

# Add event
XADD events:campaign:789 MAXLEN ~ 1000 * \
  type "impression" \
  ad_id 101 \
  timestamp 1699999999 \
  count 1

# Read events (latest)
XREAD COUNT 100 STREAMS events:campaign:789 0-0

# Read new events (blocking)
XREAD BLOCK 5000 COUNT 10 STREAMS events:campaign:789 $

# Consumer groups (for distributed processing)
XGROUP CREATE events:campaign:789 processors $ MKSTREAM
XREADGROUP GROUP processors consumer1 \
  COUNT 10 STREAMS events:campaign:789 >
```

### 6. RedisJSON: Complex Objects

```redis
# Key pattern: {type}:{id}:json
# Data structure: JSON
# TTL: Varies

# Cache AI persona
JSON.SET persona:seg_456 $ '{
  "segment_id": 456,
  "persona_name": "Tech Enthusiasts",
  "demographics": {
    "age_range": "25-34",
    "gender": {"male": 0.68, "female": 0.30}
  },
  "interests": ["AI", "Tech", "Gadgets"],
  "engagement_rate": 0.048,
  "last_computed": 1699999999
}'

# Get full object
JSON.GET persona:seg_456

# Get specific path
JSON.GET persona:seg_456 $.demographics.age_range

# Update specific field
JSON.SET persona:seg_456 $.engagement_rate 0.052

# Increment counter
JSON.NUMINCRBY persona:seg_456 $.member_count 1
```

### 7. RedisTimeSeries: Short-term Metrics

```redis
# Key pattern: metrics:{type}:{id}:{metric}
# Data structure: TimeSeries
# TTL: 1 hour (retention policy)

# Create time series
TS.CREATE metrics:campaign:789:impressions \
  RETENTION 3600 \
  LABELS campaign_id 789 metric impressions

# Add data point
TS.ADD metrics:campaign:789:impressions * 150

# Get range
TS.RANGE metrics:campaign:789:impressions \
  (NOW-3600000) + \
  AGGREGATION avg 60000  # 1-minute buckets

# Multi-get (multiple metrics)
TS.MGET FILTER campaign_id=789
```

### 8. Bitmaps: Feature Flags

```redis
# Key pattern: features:{flag_name}
# Data structure: Bitmap
# No TTL

# Set feature for user
SETBIT features:new_dashboard 456 1

# Check if enabled
GETBIT features:new_dashboard 456

# Count enabled users
BITCOUNT features:new_dashboard
```

## Cache Invalidation Strategies

### 1. Time-Based (TTL)

```python
# Short TTL for frequently changing data
def cache_follower_stats(account_id, stats):
    redis.setex(
        f"stats:account:{account_id}",
        300,  # 5 minutes
        json.dumps(stats)
    )

# Long TTL for stable data
def cache_organization_config(org_id, config):
    redis.setex(
        f"config:org:{org_id}",
        3600,  # 1 hour
        json.dumps(config)
    )
```

### 2. Event-Based Invalidation

```python
# Delete cache on data change
def update_follower(follower_id, data):
    # Update database
    db.update_follower(follower_id, data)
    
    # Invalidate caches
    redis.delete(f"follower:{follower_id}")
    redis.delete(f"stats:account:{data['social_account_id']}")
    
    # Publish invalidation event
    redis.publish(
        "cache:invalidate",
        json.dumps({"type": "follower", "id": follower_id})
    )
```

### 3. Tag-Based Invalidation

```python
# Tag-based cache with secondary index
def cache_with_tags(key, value, ttl, tags):
    # Store value
    redis.setex(key, ttl, value)
    
    # Add to tag sets
    for tag in tags:
        redis.sadd(f"cache:tag:{tag}", key)
        redis.expire(f"cache:tag:{tag}", ttl + 60)

# Invalidate by tag
def invalidate_by_tag(tag):
    keys = redis.smembers(f"cache:tag:{tag}")
    if keys:
        redis.delete(*keys)
    redis.delete(f"cache:tag:{tag}")

# Usage
cache_with_tags(
    "campaign:789:performance",
    json.dumps(data),
    300,
    tags=["campaign:789", "org:123", "platform:instagram"]
)

# Invalidate all Instagram campaign caches
invalidate_by_tag("platform:instagram")
```

## Cache Patterns

### 1. Cache-Aside (Lazy Loading)

```python
def get_follower_with_cache(follower_id):
    cache_key = f"follower:{follower_id}"
    
    # Try cache first
    cached = redis.get(cache_key)
    if cached:
        return json.loads(cached)
    
    # Cache miss: load from database
    follower = db.get_follower(follower_id)
    
    # Store in cache
    redis.setex(cache_key, 600, json.dumps(follower))
    
    return follower
```

### 2. Write-Through

```python
def update_campaign_with_cache(campaign_id, data):
    # Write to database
    db.update_campaign(campaign_id, data)
    
    # Write to cache
    cache_key = f"campaign:{campaign_id}"
    redis.setex(cache_key, 300, json.dumps(data))
    
    return data
```

### 3. Write-Behind (Async)

```python
def track_engagement(follower_id, metric_type, value):
    # Write to cache immediately
    redis.hincrby(
        f"engagement:temp:{follower_id}",
        metric_type,
        value
    )
    redis.expire(f"engagement:temp:{follower_id}", 3600)
    
    # Queue for batch database write
    redis.lpush(
        "queue:engagement_writes",
        json.dumps({
            "follower_id": follower_id,
            "metric_type": metric_type,
            "value": value,
            "timestamp": time.time()
        })
    )

# Background worker
def engagement_batch_worker():
    while True:
        # Pop batch (100 items)
        items = redis.lrange("queue:engagement_writes", 0, 99)
        redis.ltrim("queue:engagement_writes", 100, -1)
        
        if items:
            # Batch insert to database
            db.batch_insert_engagement(
                [json.loads(item) for item in items]
            )
        
        time.sleep(10)
```

### 4. Refresh-Ahead

```python
def get_campaign_metrics_with_refresh(campaign_id):
    cache_key = f"metrics:campaign:{campaign_id}"
    ttl_threshold = 60  # Refresh if TTL < 60 seconds
    
    # Get value and TTL
    cached = redis.get(cache_key)
    ttl = redis.ttl(cache_key)
    
    # Refresh in background if TTL is low
    if cached and ttl < ttl_threshold:
        # Return cached value immediately
        # Trigger async refresh
        asyncio.create_task(refresh_campaign_metrics(campaign_id))
        return json.loads(cached)
    
    if cached:
        return json.loads(cached)
    
    # Cache miss: load and cache
    metrics = compute_campaign_metrics(campaign_id)
    redis.setex(cache_key, 300, json.dumps(metrics))
    return metrics
```

## Cache Warming

### Pre-populate cache for active campaigns

```python
def warm_cache_active_campaigns():
    """Run on application startup or scheduled"""
    active_campaigns = db.get_active_campaigns()
    
    for campaign in active_campaigns:
        # Warm metrics cache
        metrics = compute_campaign_metrics(campaign.id)
        redis.setex(
            f"metrics:campaign:{campaign.id}",
            600,
            json.dumps(metrics)
        )
        
        # Warm ad creatives
        creatives = db.get_campaign_creatives(campaign.id)
        for creative in creatives:
            redis.setex(
                f"creative:{creative.id}",
                600,
                json.dumps(creative.to_dict())
            )
```

## Monitoring & Observability

### Key Metrics to Track

```python
# Cache hit rate
def track_cache_metrics(cache_key, hit):
    """Track cache hit/miss"""
    redis.hincrby("metrics:cache", "total", 1)
    if hit:
        redis.hincrby("metrics:cache", "hits", 1)
    else:
        redis.hincrby("metrics:cache", "misses", 1)

# Get cache hit rate
def get_cache_hit_rate():
    stats = redis.hgetall("metrics:cache")
    total = int(stats.get(b"total", 0))
    hits = int(stats.get(b"hits", 0))
    return (hits / total * 100) if total > 0 else 0

# Memory usage per key pattern
INFO memory
MEMORY STATS

# Slow log
SLOWLOG GET 10
```

### Redis Commands for Monitoring

```redis
# Connection stats
INFO clients

# Memory usage
INFO memory
MEMORY DOCTOR

# Key statistics
INFO keyspace

# Performance stats
INFO stats

# Replication status
INFO replication

# Find memory hogs
MEMORY USAGE key_name
```

## Best Practices

### 1. Key Naming Conventions

```
Format: {namespace}:{entity}:{id}:{attribute}

Examples:
✓ session:abc123
✓ user:456:profile
✓ stats:account:789:engagement
✓ cache:query:campaigns:active
✓ leaderboard:followers:account_123

Avoid:
✗ getUserProfile456
✗ campaign-metrics-789
✗ random_key_name
```

### 2. TTL Guidelines

```
- Sessions: 24 hours
- API rate limits: 1 hour
- User profiles: 10 minutes
- Account stats: 5 minutes
- Campaign metrics: 2 minutes
- Computed aggregates: 15 minutes
- Configuration: 1 hour
```

### 3. Memory Management

```python
# Set maxmemory and eviction policy
# redis.conf
maxmemory 16gb
maxmemory-policy allkeys-lru

# Monitor memory usage
def check_memory_usage():
    info = redis.info("memory")
    used = info["used_memory"]
    max_memory = info["maxmemory"]
    if used / max_memory > 0.9:
        # Alert: memory usage > 90%
        alert_ops_team()
```

### 4. Avoid Cache Stampede

```python
import random

def get_with_stampede_protection(key, ttl, compute_func):
    """Probabilistic early expiration"""
    value = redis.get(key)
    current_ttl = redis.ttl(key)
    
    # Probabilistic refresh
    delta = random.random() * 60  # 0-60 seconds
    if current_ttl > 0 and current_ttl < delta:
        # Refresh in background
        asyncio.create_task(refresh_cache(key, compute_func))
    
    if value:
        return json.loads(value)
    
    # Cache miss: compute and store
    value = compute_func()
    redis.setex(key, ttl, json.dumps(value))
    return value
```

### 5. Connection Pooling

```python
from redis import ConnectionPool, Redis

# Create connection pool (reuse connections)
pool = ConnectionPool(
    host='localhost',
    port=6379,
    max_connections=50,
    socket_timeout=5,
    socket_connect_timeout=5,
    retry_on_timeout=True
)

redis_client = Redis(connection_pool=pool)
```

## Security

### 1. Access Control (ACLs)

```redis
# Create read-only user
ACL SETUSER readonly \
  on >password \
  ~cache:* ~stats:* \
  +get +hget +hgetall +mget \
  -@write -@admin

# Create write user for app
ACL SETUSER app_writer \
  on >password \
  ~* \
  +@all -@dangerous
```

### 2. Encryption

```
# TLS/SSL for connections
redis-cli --tls \
  --cert /path/to/redis.crt \
  --key /path/to/redis.key \
  --cacert /path/to/ca.crt
```

### 3. Never Cache Sensitive Data in Plain Text

```python
# Bad: Caching PII
redis.set("user:123:email", "user@example.com")

# Good: Cache only IDs, fetch sensitive data from DB
redis.set("user:123:profile_id", "prof_abc")
```

## Example: Complete Cache Implementation

```python
class CacheManager:
    def __init__(self, redis_client):
        self.redis = redis_client
    
    def get_follower_stats(self, account_id):
        """Cache-aside pattern with metrics"""
        cache_key = f"stats:account:{account_id}"
        
        # Try cache
        cached = self.redis.get(cache_key)
        if cached:
            self._track_hit(cache_key)
            return json.loads(cached)
        
        # Cache miss
        self._track_miss(cache_key)
        
        # Compute stats
        stats = self._compute_stats(account_id)
        
        # Cache with TTL
        self.redis.setex(cache_key, 300, json.dumps(stats))
        
        return stats
    
    def invalidate_account_cache(self, account_id):
        """Invalidate all caches for an account"""
        patterns = [
            f"stats:account:{account_id}",
            f"followers:account:{account_id}:*",
            f"leaderboard:engagement:account_{account_id}"
        ]
        
        for pattern in patterns:
            if "*" in pattern:
                keys = self.redis.keys(pattern)
                if keys:
                    self.redis.delete(*keys)
            else:
                self.redis.delete(pattern)
    
    def _track_hit(self, key):
        self.redis.hincrby("metrics:cache:hits", key, 1)
    
    def _track_miss(self, key):
        self.redis.hincrby("metrics:cache:misses", key, 1)
```

