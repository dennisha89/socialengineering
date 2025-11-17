-- ============================================================================
-- TimescaleDB Schema for Time-Series Metrics
-- Version: 1.0
-- Description: Performance metrics, engagement data, behavioral events
-- ============================================================================

-- Enable TimescaleDB extension
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- ============================================================================
-- FOLLOWER ENGAGEMENT METRICS (Time-Series)
-- ============================================================================

CREATE TABLE follower_engagement (
  time TIMESTAMPTZ NOT NULL,
  follower_id BIGINT NOT NULL,
  social_account_id BIGINT NOT NULL,
  metric_type VARCHAR(50) NOT NULL,  -- likes, comments, shares, views, saves
  value FLOAT NOT NULL,
  platform VARCHAR(50) NOT NULL,
  post_id VARCHAR(255),  -- Optional: specific post that generated engagement
  metadata JSONB DEFAULT '{}'
);

-- Convert to hypertable (partitioned by time)
SELECT create_hypertable('follower_engagement', 'time', 
  chunk_time_interval => INTERVAL '1 day'
);

-- Create continuous aggregate: Hourly engagement
CREATE MATERIALIZED VIEW follower_engagement_hourly
WITH (timescaledb.continuous) AS
SELECT 
  time_bucket('1 hour', time) AS hour,
  follower_id,
  social_account_id,
  metric_type,
  platform,
  COUNT(*) as event_count,
  AVG(value) as avg_value,
  MAX(value) as max_value,
  SUM(value) as total_value
FROM follower_engagement
GROUP BY hour, follower_id, social_account_id, metric_type, platform
WITH NO DATA;

-- Refresh policy: Update every 30 minutes for last 2 hours
SELECT add_continuous_aggregate_policy('follower_engagement_hourly',
  start_offset => INTERVAL '3 hours',
  end_offset => INTERVAL '30 minutes',
  schedule_interval => INTERVAL '30 minutes'
);

-- Create continuous aggregate: Daily engagement
CREATE MATERIALIZED VIEW follower_engagement_daily
WITH (timescaledb.continuous) AS
SELECT 
  time_bucket('1 day', time) AS day,
  follower_id,
  social_account_id,
  metric_type,
  platform,
  COUNT(*) as event_count,
  AVG(value) as avg_value,
  MAX(value) as max_value,
  MIN(value) as min_value,
  SUM(value) as total_value,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY value) as median_value
FROM follower_engagement
GROUP BY day, follower_id, social_account_id, metric_type, platform
WITH NO DATA;

-- Refresh policy: Update daily aggregates every 6 hours
SELECT add_continuous_aggregate_policy('follower_engagement_daily',
  start_offset => INTERVAL '3 days',
  end_offset => INTERVAL '1 hour',
  schedule_interval => INTERVAL '6 hours'
);

-- Compression: Compress chunks older than 7 days (10-20x reduction)
ALTER TABLE follower_engagement SET (
  timescaledb.compress,
  timescaledb.compress_segmentby = 'follower_id, social_account_id, metric_type, platform',
  timescaledb.compress_orderby = 'time DESC'
);

SELECT add_compression_policy('follower_engagement', INTERVAL '7 days');

-- Retention: Keep raw data for 90 days
SELECT add_retention_policy('follower_engagement', INTERVAL '90 days');

-- ============================================================================
-- BEHAVIORAL EVENTS (Clickstream, Page Views, etc.)
-- ============================================================================

CREATE TABLE behavioral_events (
  time TIMESTAMPTZ NOT NULL,
  follower_id BIGINT NOT NULL,
  social_account_id BIGINT NOT NULL,
  event_type VARCHAR(100) NOT NULL,  -- page_view, click, scroll, video_play, etc.
  event_category VARCHAR(50),  -- navigation, engagement, conversion
  properties JSONB DEFAULT '{}',  -- Flexible event properties
  session_id VARCHAR(255),
  platform VARCHAR(50),
  user_agent TEXT,
  ip_address INET
);

SELECT create_hypertable('behavioral_events', 'time',
  chunk_time_interval => INTERVAL '1 day'
);

-- Hourly event aggregates
CREATE MATERIALIZED VIEW behavioral_events_hourly
WITH (timescaledb.continuous) AS
SELECT 
  time_bucket('1 hour', time) AS hour,
  social_account_id,
  event_type,
  event_category,
  platform,
  COUNT(*) as event_count,
  COUNT(DISTINCT follower_id) as unique_followers,
  COUNT(DISTINCT session_id) as unique_sessions
FROM behavioral_events
GROUP BY hour, social_account_id, event_type, event_category, platform
WITH NO DATA;

SELECT add_continuous_aggregate_policy('behavioral_events_hourly',
  start_offset => INTERVAL '3 hours',
  end_offset => INTERVAL '30 minutes',
  schedule_interval => INTERVAL '30 minutes'
);

-- Compression
ALTER TABLE behavioral_events SET (
  timescaledb.compress,
  timescaledb.compress_segmentby = 'social_account_id, event_type, platform',
  timescaledb.compress_orderby = 'time DESC'
);

SELECT add_compression_policy('behavioral_events', INTERVAL '7 days');

-- Retention: Keep events for 180 days
SELECT add_retention_policy('behavioral_events', INTERVAL '180 days');

-- ============================================================================
-- CAMPAIGN METRICS (Ad Performance)
-- ============================================================================

CREATE TABLE campaign_metrics (
  time TIMESTAMPTZ NOT NULL,
  campaign_id BIGINT NOT NULL,
  ad_creative_id BIGINT,
  ad_group_id BIGINT,
  
  platform VARCHAR(50) NOT NULL,
  
  -- Core metrics
  impressions INT DEFAULT 0,
  clicks INT DEFAULT 0,
  conversions INT DEFAULT 0,
  
  -- Financial metrics
  spend DECIMAL(12, 4) DEFAULT 0,
  revenue DECIMAL(12, 4) DEFAULT 0,
  
  -- Engagement metrics
  likes INT DEFAULT 0,
  shares INT DEFAULT 0,
  comments INT DEFAULT 0,
  saves INT DEFAULT 0,
  
  -- Video metrics (if applicable)
  video_views INT DEFAULT 0,
  video_completion_rate FLOAT,
  
  -- Targeting
  segment_id BIGINT,
  geo_country VARCHAR(2),
  geo_city VARCHAR(100),
  age_range VARCHAR(20),
  gender VARCHAR(20)
);

SELECT create_hypertable('campaign_metrics', 'time',
  chunk_time_interval => INTERVAL '1 day'
);

-- Hourly campaign performance
CREATE MATERIALIZED VIEW campaign_metrics_hourly
WITH (timescaledb.continuous) AS
SELECT 
  time_bucket('1 hour', time) AS hour,
  campaign_id,
  ad_creative_id,
  platform,
  
  SUM(impressions) as total_impressions,
  SUM(clicks) as total_clicks,
  SUM(conversions) as total_conversions,
  SUM(spend) as total_spend,
  SUM(revenue) as total_revenue,
  
  -- Calculated metrics
  CASE 
    WHEN SUM(impressions) > 0 
    THEN (SUM(clicks)::float / SUM(impressions)) * 100 
    ELSE 0 
  END as ctr_percent,
  
  CASE 
    WHEN SUM(clicks) > 0 
    THEN SUM(spend) / SUM(clicks) 
    ELSE 0 
  END as cpc,
  
  CASE 
    WHEN SUM(impressions) > 0 
    THEN SUM(spend) / (SUM(impressions) / 1000.0)
    ELSE 0 
  END as cpm,
  
  CASE 
    WHEN SUM(conversions) > 0 
    THEN SUM(spend) / SUM(conversions) 
    ELSE 0 
  END as cpa,
  
  CASE 
    WHEN SUM(spend) > 0 
    THEN ((SUM(revenue) - SUM(spend)) / SUM(spend)) * 100 
    ELSE 0 
  END as roas_percent
  
FROM campaign_metrics
GROUP BY hour, campaign_id, ad_creative_id, platform
WITH NO DATA;

SELECT add_continuous_aggregate_policy('campaign_metrics_hourly',
  start_offset => INTERVAL '3 hours',
  end_offset => INTERVAL '15 minutes',
  schedule_interval => INTERVAL '15 minutes'
);

-- Daily campaign performance (for long-term analysis)
CREATE MATERIALIZED VIEW campaign_metrics_daily
WITH (timescaledb.continuous) AS
SELECT 
  time_bucket('1 day', time) AS day,
  campaign_id,
  ad_creative_id,
  ad_group_id,
  platform,
  segment_id,
  
  SUM(impressions) as total_impressions,
  SUM(clicks) as total_clicks,
  SUM(conversions) as total_conversions,
  SUM(spend) as total_spend,
  SUM(revenue) as total_revenue,
  SUM(likes) as total_likes,
  SUM(shares) as total_shares,
  SUM(comments) as total_comments,
  
  AVG(video_completion_rate) as avg_video_completion_rate,
  
  -- Calculated metrics
  CASE 
    WHEN SUM(impressions) > 0 
    THEN (SUM(clicks)::float / SUM(impressions)) * 100 
    ELSE 0 
  END as ctr_percent,
  
  CASE 
    WHEN SUM(clicks) > 0 
    THEN SUM(spend) / SUM(clicks) 
    ELSE 0 
  END as cpc,
  
  CASE 
    WHEN SUM(conversions) > 0 
    THEN (SUM(conversions)::float / SUM(clicks)) * 100 
    ELSE 0 
  END as conversion_rate_percent
  
FROM campaign_metrics
GROUP BY day, campaign_id, ad_creative_id, ad_group_id, platform, segment_id
WITH NO DATA;

SELECT add_continuous_aggregate_policy('campaign_metrics_daily',
  start_offset => INTERVAL '3 days',
  end_offset => INTERVAL '1 hour',
  schedule_interval => INTERVAL '6 hours'
);

-- Compression
ALTER TABLE campaign_metrics SET (
  timescaledb.compress,
  timescaledb.compress_segmentby = 'campaign_id, ad_creative_id, platform',
  timescaledb.compress_orderby = 'time DESC'
);

SELECT add_compression_policy('campaign_metrics', INTERVAL '7 days');

-- Retention: Keep raw metrics for 2 years
SELECT add_retention_policy('campaign_metrics', INTERVAL '730 days');

-- ============================================================================
-- AI MODEL PERFORMANCE METRICS
-- ============================================================================

CREATE TABLE ai_model_metrics (
  time TIMESTAMPTZ NOT NULL,
  model_id BIGINT NOT NULL,
  model_version VARCHAR(50) NOT NULL,
  
  -- Performance metrics
  predictions_count INT DEFAULT 0,
  accuracy FLOAT,
  precision_score FLOAT,
  recall SCORE FLOAT,
  f1_score FLOAT,
  
  -- Latency metrics
  avg_inference_time_ms FLOAT,
  p95_inference_time_ms FLOAT,
  p99_inference_time_ms FLOAT,
  
  -- Resource usage
  cpu_usage_percent FLOAT,
  memory_usage_mb FLOAT,
  gpu_usage_percent FLOAT,
  
  -- Error tracking
  error_count INT DEFAULT 0,
  error_rate FLOAT,
  
  metadata JSONB DEFAULT '{}'
);

SELECT create_hypertable('ai_model_metrics', 'time',
  chunk_time_interval => INTERVAL '1 day'
);

-- Hourly model performance
CREATE MATERIALIZED VIEW ai_model_metrics_hourly
WITH (timescaledb.continuous) AS
SELECT 
  time_bucket('1 hour', time) AS hour,
  model_id,
  model_version,
  
  SUM(predictions_count) as total_predictions,
  AVG(accuracy) as avg_accuracy,
  AVG(f1_score) as avg_f1_score,
  AVG(avg_inference_time_ms) as avg_inference_time_ms,
  MAX(p99_inference_time_ms) as max_p99_inference_time_ms,
  SUM(error_count) as total_errors,
  AVG(error_rate) as avg_error_rate
  
FROM ai_model_metrics
GROUP BY hour, model_id, model_version
WITH NO DATA;

SELECT add_continuous_aggregate_policy('ai_model_metrics_hourly',
  start_offset => INTERVAL '3 hours',
  end_offset => INTERVAL '30 minutes',
  schedule_interval => INTERVAL '30 minutes'
);

-- Compression
ALTER TABLE ai_model_metrics SET (
  timescaledb.compress,
  timescaledb.compress_segmentby = 'model_id, model_version',
  timescaledb.compress_orderby = 'time DESC'
);

SELECT add_compression_policy('ai_model_metrics', INTERVAL '7 days');

-- Retention: Keep model metrics for 1 year
SELECT add_retention_policy('ai_model_metrics', INTERVAL '365 days');

-- ============================================================================
-- SYSTEM HEALTH METRICS
-- ============================================================================

CREATE TABLE system_metrics (
  time TIMESTAMPTZ NOT NULL,
  service_name VARCHAR(100) NOT NULL,
  instance_id VARCHAR(100),
  
  -- Application metrics
  request_count INT DEFAULT 0,
  error_count INT DEFAULT 0,
  avg_response_time_ms FLOAT,
  p95_response_time_ms FLOAT,
  p99_response_time_ms FLOAT,
  
  -- Resource metrics
  cpu_percent FLOAT,
  memory_percent FLOAT,
  disk_percent FLOAT,
  
  -- Database metrics
  db_connections INT,
  db_query_time_ms FLOAT,
  
  -- Cache metrics
  cache_hit_rate FLOAT,
  cache_miss_rate FLOAT,
  
  tags JSONB DEFAULT '{}'
);

SELECT create_hypertable('system_metrics', 'time',
  chunk_time_interval => INTERVAL '1 day'
);

-- 5-minute rollups
CREATE MATERIALIZED VIEW system_metrics_5min
WITH (timescaledb.continuous) AS
SELECT 
  time_bucket('5 minutes', time) AS time_5min,
  service_name,
  
  SUM(request_count) as total_requests,
  SUM(error_count) as total_errors,
  AVG(avg_response_time_ms) as avg_response_time_ms,
  MAX(p99_response_time_ms) as max_p99_response_time_ms,
  AVG(cpu_percent) as avg_cpu_percent,
  AVG(memory_percent) as avg_memory_percent,
  AVG(cache_hit_rate) as avg_cache_hit_rate
  
FROM system_metrics
GROUP BY time_5min, service_name
WITH NO DATA;

SELECT add_continuous_aggregate_policy('system_metrics_5min',
  start_offset => INTERVAL '1 hour',
  end_offset => INTERVAL '5 minutes',
  schedule_interval => INTERVAL '5 minutes'
);

-- Compression
ALTER TABLE system_metrics SET (
  timescaledb.compress,
  timescaledb.compress_segmentby = 'service_name, instance_id',
  timescaledb.compress_orderby = 'time DESC'
);

SELECT add_compression_policy('system_metrics', INTERVAL '3 days');

-- Retention: Keep system metrics for 90 days
SELECT add_retention_policy('system_metrics', INTERVAL '90 days');

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Follower engagement
CREATE INDEX idx_follower_engagement_follower_time 
  ON follower_engagement(follower_id, time DESC);
  
CREATE INDEX idx_follower_engagement_account_time 
  ON follower_engagement(social_account_id, time DESC);
  
CREATE INDEX idx_follower_engagement_metric_time 
  ON follower_engagement(metric_type, time DESC);

-- Behavioral events
CREATE INDEX idx_behavioral_events_follower_time 
  ON behavioral_events(follower_id, time DESC);
  
CREATE INDEX idx_behavioral_events_session 
  ON behavioral_events(session_id, time DESC);
  
CREATE INDEX idx_behavioral_events_type_time 
  ON behavioral_events(event_type, time DESC);

-- Campaign metrics
CREATE INDEX idx_campaign_metrics_campaign_time 
  ON campaign_metrics(campaign_id, time DESC);
  
CREATE INDEX idx_campaign_metrics_creative_time 
  ON campaign_metrics(ad_creative_id, time DESC);
  
CREATE INDEX idx_campaign_metrics_platform_time 
  ON campaign_metrics(platform, time DESC);

-- AI model metrics
CREATE INDEX idx_ai_model_metrics_model_time 
  ON ai_model_metrics(model_id, time DESC);

-- System metrics
CREATE INDEX idx_system_metrics_service_time 
  ON system_metrics(service_name, time DESC);

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function to get engagement rate for a follower over time period
CREATE OR REPLACE FUNCTION get_follower_engagement_rate(
  p_follower_id BIGINT,
  p_start_time TIMESTAMPTZ,
  p_end_time TIMESTAMPTZ
)
RETURNS FLOAT AS $$
DECLARE
  total_engagement FLOAT;
  follower_count INT;
BEGIN
  SELECT SUM(total_value), COUNT(DISTINCT follower_id)
  INTO total_engagement, follower_count
  FROM follower_engagement_daily
  WHERE follower_id = p_follower_id
    AND day >= p_start_time
    AND day < p_end_time;
  
  IF follower_count > 0 THEN
    RETURN total_engagement / follower_count;
  ELSE
    RETURN 0;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to get campaign ROI
CREATE OR REPLACE FUNCTION get_campaign_roi(
  p_campaign_id BIGINT,
  p_start_time TIMESTAMPTZ,
  p_end_time TIMESTAMPTZ
)
RETURNS FLOAT AS $$
DECLARE
  total_spend DECIMAL(12, 4);
  total_revenue DECIMAL(12, 4);
BEGIN
  SELECT SUM(total_spend), SUM(total_revenue)
  INTO total_spend, total_revenue
  FROM campaign_metrics_daily
  WHERE campaign_id = p_campaign_id
    AND day >= p_start_time
    AND day < p_end_time;
  
  IF total_spend > 0 THEN
    RETURN ((total_revenue - total_spend) / total_spend) * 100;
  ELSE
    RETURN 0;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- SAMPLE QUERIES
-- ============================================================================

-- Get top performing campaigns in last 7 days
-- SELECT 
--   campaign_id,
--   SUM(total_impressions) as impressions,
--   SUM(total_clicks) as clicks,
--   AVG(ctr_percent) as avg_ctr,
--   SUM(total_spend) as spend,
--   SUM(total_revenue) as revenue
-- FROM campaign_metrics_daily
-- WHERE day > NOW() - INTERVAL '7 days'
-- GROUP BY campaign_id
-- ORDER BY revenue DESC
-- LIMIT 10;

-- Get hourly engagement trends for a follower
-- SELECT 
--   hour,
--   metric_type,
--   SUM(total_value) as total_engagement
-- FROM follower_engagement_hourly
-- WHERE follower_id = 12345
--   AND hour > NOW() - INTERVAL '24 hours'
-- GROUP BY hour, metric_type
-- ORDER BY hour DESC;

-- Get real-time campaign performance (last 15 minutes)
-- SELECT 
--   time_bucket('1 minute', time) AS minute,
--   SUM(impressions) as impressions,
--   SUM(clicks) as clicks,
--   SUM(spend) as spend
-- FROM campaign_metrics
-- WHERE campaign_id = 789
--   AND time > NOW() - INTERVAL '15 minutes'
-- GROUP BY minute
-- ORDER BY minute DESC;

