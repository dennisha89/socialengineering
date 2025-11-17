-- ============================================================================
-- Snowflake Data Warehouse Schema for Analytics & BI
-- Version: 1.0
-- Description: Star schema for historical analytics and reporting
-- ============================================================================

-- Create databases and schemas
CREATE DATABASE IF NOT EXISTS social_intelligence_dw;
USE DATABASE social_intelligence_dw;

CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS dimensions;
CREATE SCHEMA IF NOT EXISTS facts;
CREATE SCHEMA IF NOT EXISTS aggregates;

-- ============================================================================
-- DIMENSION TABLES
-- ============================================================================

USE SCHEMA dimensions;

-- Dimension: Date (standard date dimension)
CREATE OR REPLACE TABLE dim_date (
  date_key INT PRIMARY KEY,
  full_date DATE NOT NULL,
  year INT NOT NULL,
  quarter INT NOT NULL,
  month INT NOT NULL,
  week INT NOT NULL,
  day_of_month INT NOT NULL,
  day_of_week INT NOT NULL,
  day_of_year INT NOT NULL,
  day_name VARCHAR(10) NOT NULL,
  month_name VARCHAR(10) NOT NULL,
  quarter_name VARCHAR(10) NOT NULL,
  is_weekend BOOLEAN NOT NULL,
  is_holiday BOOLEAN NOT NULL,
  fiscal_year INT,
  fiscal_quarter INT
);

-- Dimension: Time (for intraday analysis)
CREATE OR REPLACE TABLE dim_time (
  time_key INT PRIMARY KEY,
  hour INT NOT NULL,
  minute INT NOT NULL,
  second INT NOT NULL,
  time_of_day VARCHAR(20) NOT NULL,  -- Morning, Afternoon, Evening, Night
  is_business_hours BOOLEAN NOT NULL
);

-- Dimension: Organization (SCD Type 2)
CREATE OR REPLACE TABLE dim_organization (
  organization_key INT AUTOINCREMENT PRIMARY KEY,
  organization_id BIGINT NOT NULL,
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(100) NOT NULL,
  tier VARCHAR(50) NOT NULL,
  status VARCHAR(50) NOT NULL,
  industry VARCHAR(100),
  region VARCHAR(100),
  company_size VARCHAR(50),
  
  -- SCD Type 2 fields
  effective_date DATE NOT NULL,
  expiration_date DATE,
  is_current BOOLEAN NOT NULL DEFAULT TRUE,
  
  -- Metadata
  created_date DATE NOT NULL,
  updated_date DATE NOT NULL
);

-- Dimension: Social Platform
CREATE OR REPLACE TABLE dim_platform (
  platform_key INT PRIMARY KEY,
  platform_name VARCHAR(50) NOT NULL UNIQUE,
  platform_category VARCHAR(50),  -- social_media, messaging, video
  parent_company VARCHAR(100)
);

-- Insert static platform data
INSERT INTO dim_platform VALUES
(1, 'instagram', 'social_media', 'Meta'),
(2, 'facebook', 'social_media', 'Meta'),
(3, 'twitter', 'social_media', 'X Corp'),
(4, 'linkedin', 'social_media', 'Microsoft'),
(5, 'tiktok', 'video', 'ByteDance'),
(6, 'youtube', 'video', 'Google');

-- Dimension: Campaign
CREATE OR REPLACE TABLE dim_campaign (
  campaign_key INT AUTOINCREMENT PRIMARY KEY,
  campaign_id BIGINT NOT NULL,
  organization_key INT NOT NULL,
  
  name VARCHAR(255) NOT NULL,
  objective VARCHAR(100) NOT NULL,
  status VARCHAR(50) NOT NULL,
  
  budget_total DECIMAL(12, 2),
  budget_daily DECIMAL(12, 2),
  currency VARCHAR(3),
  
  start_date DATE,
  end_date DATE,
  
  -- SCD Type 2
  effective_date DATE NOT NULL,
  expiration_date DATE,
  is_current BOOLEAN NOT NULL DEFAULT TRUE,
  
  FOREIGN KEY (organization_key) REFERENCES dim_organization(organization_key)
);

-- Dimension: Ad Creative
CREATE OR REPLACE TABLE dim_ad_creative (
  ad_creative_key INT AUTOINCREMENT PRIMARY KEY,
  ad_creative_id BIGINT NOT NULL,
  campaign_key INT NOT NULL,
  
  name VARCHAR(255) NOT NULL,
  format VARCHAR(50) NOT NULL,
  ai_generated BOOLEAN NOT NULL,
  ai_model_used VARCHAR(100),
  
  variant_group VARCHAR(100),
  
  -- SCD Type 2
  effective_date DATE NOT NULL,
  expiration_date DATE,
  is_current BOOLEAN NOT NULL DEFAULT TRUE,
  
  FOREIGN KEY (campaign_key) REFERENCES dim_campaign(campaign_key)
);

-- Dimension: Segment
CREATE OR REPLACE TABLE dim_segment (
  segment_key INT AUTOINCREMENT PRIMARY KEY,
  segment_id BIGINT NOT NULL,
  organization_key INT NOT NULL,
  
  name VARCHAR(255) NOT NULL,
  segment_type VARCHAR(50) NOT NULL,
  ai_model_used VARCHAR(100),
  
  persona_name VARCHAR(255),
  
  member_count INT,
  avg_engagement_rate FLOAT,
  
  -- SCD Type 2
  effective_date DATE NOT NULL,
  expiration_date DATE,
  is_current BOOLEAN NOT NULL DEFAULT TRUE,
  
  FOREIGN KEY (organization_key) REFERENCES dim_organization(organization_key)
);

-- Dimension: Follower (Large, potentially billions of rows)
CREATE OR REPLACE TABLE dim_follower (
  follower_key BIGINT AUTOINCREMENT PRIMARY KEY,
  follower_id BIGINT NOT NULL,
  platform_key INT NOT NULL,
  
  username VARCHAR(255),
  verified BOOLEAN,
  
  -- Demographics
  age_range VARCHAR(20),
  gender VARCHAR(20),
  location_country VARCHAR(2),
  location_city VARCHAR(100),
  
  -- Categorization
  primary_interest VARCHAR(100),
  follower_tier VARCHAR(50),  -- micro, macro, mega (based on follower count)
  
  -- Engagement
  avg_engagement_rate FLOAT,
  
  -- SCD Type 2
  effective_date DATE NOT NULL,
  expiration_date DATE,
  is_current BOOLEAN NOT NULL DEFAULT TRUE,
  
  FOREIGN KEY (platform_key) REFERENCES dim_platform(platform_key)
);

-- Cluster by commonly filtered columns
ALTER TABLE dim_follower CLUSTER BY (platform_key, location_country);

-- Dimension: Geography
CREATE OR REPLACE TABLE dim_geography (
  geography_key INT AUTOINCREMENT PRIMARY KEY,
  country_code VARCHAR(2) NOT NULL,
  country_name VARCHAR(100) NOT NULL,
  region VARCHAR(100),  -- North America, Europe, etc.
  continent VARCHAR(50),
  city_name VARCHAR(100),
  latitude FLOAT,
  longitude FLOAT
);

-- ============================================================================
-- FACT TABLES
-- ============================================================================

USE SCHEMA facts;

-- Fact: Campaign Performance (Daily grain)
CREATE OR REPLACE TABLE fact_campaign_performance (
  date_key INT NOT NULL,
  campaign_key INT NOT NULL,
  ad_creative_key INT,
  platform_key INT NOT NULL,
  segment_key INT,
  geography_key INT,
  
  -- Metrics
  impressions BIGINT DEFAULT 0,
  clicks BIGINT DEFAULT 0,
  conversions BIGINT DEFAULT 0,
  
  spend DECIMAL(12, 4) DEFAULT 0,
  revenue DECIMAL(12, 4) DEFAULT 0,
  
  likes BIGINT DEFAULT 0,
  shares BIGINT DEFAULT 0,
  comments BIGINT DEFAULT 0,
  saves BIGINT DEFAULT 0,
  
  video_views BIGINT DEFAULT 0,
  video_completion_rate FLOAT,
  
  -- Calculated metrics (pre-computed for performance)
  ctr FLOAT,  -- Click-through rate
  cvr FLOAT,  -- Conversion rate
  cpc DECIMAL(12, 4),  -- Cost per click
  cpm DECIMAL(12, 4),  -- Cost per mille
  cpa DECIMAL(12, 4),  -- Cost per acquisition
  roas FLOAT,  -- Return on ad spend
  
  -- Foreign keys
  FOREIGN KEY (date_key) REFERENCES dimensions.dim_date(date_key),
  FOREIGN KEY (campaign_key) REFERENCES dimensions.dim_campaign(campaign_key),
  FOREIGN KEY (ad_creative_key) REFERENCES dimensions.dim_ad_creative(ad_creative_key),
  FOREIGN KEY (platform_key) REFERENCES dimensions.dim_platform(platform_key),
  FOREIGN KEY (segment_key) REFERENCES dimensions.dim_segment(segment_key),
  FOREIGN KEY (geography_key) REFERENCES dimensions.dim_geography(geography_key)
);

-- Cluster by date and campaign for query performance
ALTER TABLE fact_campaign_performance 
  CLUSTER BY (date_key, campaign_key, platform_key);

-- Fact: Follower Engagement (Daily grain per follower)
CREATE OR REPLACE TABLE fact_follower_engagement (
  date_key INT NOT NULL,
  follower_key BIGINT NOT NULL,
  platform_key INT NOT NULL,
  
  -- Engagement metrics
  likes_given INT DEFAULT 0,
  comments_given INT DEFAULT 0,
  shares_given INT DEFAULT 0,
  posts_created INT DEFAULT 0,
  stories_created INT DEFAULT 0,
  
  -- Calculated
  engagement_score FLOAT,
  activity_score FLOAT,
  
  FOREIGN KEY (date_key) REFERENCES dimensions.dim_date(date_key),
  FOREIGN KEY (follower_key) REFERENCES dimensions.dim_follower(follower_key),
  FOREIGN KEY (platform_key) REFERENCES dimensions.dim_platform(platform_key)
);

ALTER TABLE fact_follower_engagement 
  CLUSTER BY (date_key, platform_key);

-- Fact: AI Model Performance
CREATE OR REPLACE TABLE fact_model_performance (
  date_key INT NOT NULL,
  model_id BIGINT NOT NULL,
  model_version VARCHAR(50) NOT NULL,
  
  predictions_count BIGINT DEFAULT 0,
  accuracy FLOAT,
  precision_score FLOAT,
  recall_score FLOAT,
  f1_score FLOAT,
  
  avg_inference_time_ms FLOAT,
  error_count BIGINT DEFAULT 0,
  
  FOREIGN KEY (date_key) REFERENCES dimensions.dim_date(date_key)
);

-- Fact: Segment Performance (How well segments perform in campaigns)
CREATE OR REPLACE TABLE fact_segment_performance (
  date_key INT NOT NULL,
  segment_key INT NOT NULL,
  campaign_key INT NOT NULL,
  
  targeted_followers BIGINT,
  reached_followers BIGINT,
  engaged_followers BIGINT,
  converted_followers BIGINT,
  
  total_impressions BIGINT DEFAULT 0,
  total_clicks BIGINT DEFAULT 0,
  total_spend DECIMAL(12, 4) DEFAULT 0,
  total_revenue DECIMAL(12, 4) DEFAULT 0,
  
  avg_engagement_rate FLOAT,
  segment_ctr FLOAT,
  segment_cvr FLOAT,
  segment_roas FLOAT,
  
  FOREIGN KEY (date_key) REFERENCES dimensions.dim_date(date_key),
  FOREIGN KEY (segment_key) REFERENCES dimensions.dim_segment(segment_key),
  FOREIGN KEY (campaign_key) REFERENCES dimensions.dim_campaign(campaign_key)
);

-- ============================================================================
-- AGGREGATE TABLES (Pre-computed for common queries)
-- ============================================================================

USE SCHEMA aggregates;

-- Weekly Campaign Summary
CREATE OR REPLACE TABLE agg_campaign_weekly (
  week_start_date DATE NOT NULL,
  campaign_key INT NOT NULL,
  platform_key INT NOT NULL,
  
  total_impressions BIGINT,
  total_clicks BIGINT,
  total_conversions BIGINT,
  total_spend DECIMAL(12, 4),
  total_revenue DECIMAL(12, 4),
  
  avg_ctr FLOAT,
  avg_cpc DECIMAL(12, 4),
  avg_roas FLOAT,
  
  PRIMARY KEY (week_start_date, campaign_key, platform_key)
);

-- Monthly Organization Summary
CREATE OR REPLACE TABLE agg_organization_monthly (
  month_start_date DATE NOT NULL,
  organization_key INT NOT NULL,
  
  active_campaigns INT,
  total_spend DECIMAL(12, 4),
  total_revenue DECIMAL(12, 4),
  total_followers_tracked BIGINT,
  
  avg_engagement_rate FLOAT,
  avg_campaign_roas FLOAT,
  
  PRIMARY KEY (month_start_date, organization_key)
);

-- Top Performing Segments (Rolling 30 days)
CREATE OR REPLACE TABLE agg_top_segments (
  as_of_date DATE NOT NULL,
  segment_key INT NOT NULL,
  rank INT NOT NULL,
  
  total_revenue DECIMAL(12, 4),
  total_conversions BIGINT,
  avg_roas FLOAT,
  
  PRIMARY KEY (as_of_date, segment_key)
);

-- ============================================================================
-- VIEWS (Business Logic Layer)
-- ============================================================================

USE SCHEMA facts;

-- View: Campaign ROI Analysis
CREATE OR REPLACE VIEW vw_campaign_roi AS
SELECT 
  dd.full_date,
  dd.year,
  dd.quarter,
  dd.month,
  do.name AS organization_name,
  do.tier AS organization_tier,
  dc.name AS campaign_name,
  dc.objective AS campaign_objective,
  dp.platform_name,
  
  SUM(f.impressions) AS total_impressions,
  SUM(f.clicks) AS total_clicks,
  SUM(f.conversions) AS total_conversions,
  SUM(f.spend) AS total_spend,
  SUM(f.revenue) AS total_revenue,
  
  -- Calculated metrics
  CASE 
    WHEN SUM(f.impressions) > 0 
    THEN (SUM(f.clicks)::FLOAT / SUM(f.impressions)) * 100 
    ELSE 0 
  END AS ctr_percent,
  
  CASE 
    WHEN SUM(f.clicks) > 0 
    THEN SUM(f.spend) / SUM(f.clicks) 
    ELSE 0 
  END AS cpc,
  
  CASE 
    WHEN SUM(f.spend) > 0 
    THEN ((SUM(f.revenue) - SUM(f.spend)) / SUM(f.spend)) * 100 
    ELSE 0 
  END AS roi_percent,
  
  CASE 
    WHEN SUM(f.spend) > 0 
    THEN SUM(f.revenue) / SUM(f.spend)
    ELSE 0 
  END AS roas

FROM fact_campaign_performance f
JOIN dimensions.dim_date dd ON f.date_key = dd.date_key
JOIN dimensions.dim_campaign dc ON f.campaign_key = dc.campaign_key
JOIN dimensions.dim_organization do ON dc.organization_key = do.organization_key
JOIN dimensions.dim_platform dp ON f.platform_key = dp.platform_key

WHERE dc.is_current = TRUE
  AND do.is_current = TRUE

GROUP BY 
  dd.full_date, dd.year, dd.quarter, dd.month,
  do.name, do.tier, dc.name, dc.objective, dp.platform_name;

-- View: Segment Performance Ranking
CREATE OR REPLACE VIEW vw_segment_ranking AS
SELECT 
  ds.name AS segment_name,
  ds.segment_type,
  ds.persona_name,
  do.name AS organization_name,
  
  SUM(f.total_impressions) AS total_impressions,
  SUM(f.total_clicks) AS total_clicks,
  SUM(f.total_conversions) AS total_conversions,
  SUM(f.total_spend) AS total_spend,
  SUM(f.total_revenue) AS total_revenue,
  
  AVG(f.segment_roas) AS avg_roas,
  AVG(f.avg_engagement_rate) AS avg_engagement_rate,
  
  RANK() OVER (
    PARTITION BY do.organization_key 
    ORDER BY SUM(f.total_revenue) DESC
  ) AS revenue_rank,
  
  RANK() OVER (
    PARTITION BY do.organization_key 
    ORDER BY AVG(f.segment_roas) DESC
  ) AS roas_rank

FROM fact_segment_performance f
JOIN dimensions.dim_segment ds ON f.segment_key = ds.segment_key
JOIN dimensions.dim_organization do ON ds.organization_key = do.organization_key
JOIN dimensions.dim_date dd ON f.date_key = dd.date_key

WHERE ds.is_current = TRUE
  AND dd.full_date >= DATEADD(day, -30, CURRENT_DATE())  -- Last 30 days

GROUP BY 
  ds.name, ds.segment_type, ds.persona_name, 
  do.name, do.organization_key;

-- View: AI vs Human Creative Performance
CREATE OR REPLACE VIEW vw_ai_creative_comparison AS
SELECT 
  dd.month,
  dd.year,
  dp.platform_name,
  dac.ai_generated,
  CASE 
    WHEN dac.ai_generated THEN 'AI-Generated'
    ELSE 'Human-Created'
  END AS creative_source,
  
  COUNT(DISTINCT dac.ad_creative_key) AS total_creatives,
  SUM(f.impressions) AS total_impressions,
  SUM(f.clicks) AS total_clicks,
  SUM(f.conversions) AS total_conversions,
  
  AVG(f.ctr) AS avg_ctr,
  AVG(f.cvr) AS avg_cvr,
  AVG(f.cpc) AS avg_cpc,
  AVG(f.roas) AS avg_roas

FROM fact_campaign_performance f
JOIN dimensions.dim_date dd ON f.date_key = dd.date_key
JOIN dimensions.dim_ad_creative dac ON f.ad_creative_key = dac.ad_creative_key
JOIN dimensions.dim_platform dp ON f.platform_key = dp.platform_key

WHERE dac.is_current = TRUE

GROUP BY 
  dd.month, dd.year, dp.platform_name, 
  dac.ai_generated;

-- ============================================================================
-- ETL STAGING TABLES
-- ============================================================================

USE SCHEMA staging;

-- Staging table for daily loads from PostgreSQL
CREATE OR REPLACE TABLE stg_campaign_metrics (
  load_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  
  campaign_id BIGINT,
  ad_creative_id BIGINT,
  platform VARCHAR(50),
  date DATE,
  
  impressions BIGINT,
  clicks BIGINT,
  conversions BIGINT,
  spend DECIMAL(12, 4),
  revenue DECIMAL(12, 4),
  
  -- Will be looked up and replaced with dimension keys
  organization_id BIGINT,
  segment_id BIGINT,
  geography_country VARCHAR(2)
);

-- ============================================================================
-- TASKS (Automated ETL)
-- ============================================================================

-- Task: Daily ETL from operational database
CREATE OR REPLACE TASK task_daily_etl
  WAREHOUSE = compute_wh
  SCHEDULE = 'USING CRON 0 2 * * * UTC'  -- 2 AM UTC daily
AS
BEGIN
  -- Load staging data (via Snowpipe or external table)
  -- Transform and load into fact tables
  -- Refresh aggregate tables
  -- Update SCD Type 2 dimensions
  
  -- Example: Refresh weekly aggregates
  MERGE INTO aggregates.agg_campaign_weekly target
  USING (
    SELECT 
      DATE_TRUNC('week', dd.full_date) AS week_start_date,
      f.campaign_key,
      f.platform_key,
      SUM(f.impressions) AS total_impressions,
      SUM(f.clicks) AS total_clicks,
      SUM(f.conversions) AS total_conversions,
      SUM(f.spend) AS total_spend,
      SUM(f.revenue) AS total_revenue,
      AVG(f.ctr) AS avg_ctr,
      AVG(f.cpc) AS avg_cpc,
      AVG(f.roas) AS avg_roas
    FROM facts.fact_campaign_performance f
    JOIN dimensions.dim_date dd ON f.date_key = dd.date_key
    WHERE dd.full_date >= DATEADD(week, -1, CURRENT_DATE())
    GROUP BY week_start_date, f.campaign_key, f.platform_key
  ) source
  ON target.week_start_date = source.week_start_date
    AND target.campaign_key = source.campaign_key
    AND target.platform_key = source.platform_key
  WHEN MATCHED THEN UPDATE SET
    target.total_impressions = source.total_impressions,
    target.total_clicks = source.total_clicks,
    target.total_conversions = source.total_conversions,
    target.total_spend = source.total_spend,
    target.total_revenue = source.total_revenue,
    target.avg_ctr = source.avg_ctr,
    target.avg_cpc = source.avg_cpc,
    target.avg_roas = source.avg_roas
  WHEN NOT MATCHED THEN INSERT (
    week_start_date, campaign_key, platform_key,
    total_impressions, total_clicks, total_conversions,
    total_spend, total_revenue, avg_ctr, avg_cpc, avg_roas
  ) VALUES (
    source.week_start_date, source.campaign_key, source.platform_key,
    source.total_impressions, source.total_clicks, source.total_conversions,
    source.total_spend, source.total_revenue, source.avg_ctr, source.avg_cpc, source.avg_roas
  );
END;

-- Resume task
ALTER TASK task_daily_etl RESUME;

-- ============================================================================
-- DATA GOVERNANCE
-- ============================================================================

-- Row access policy (example for multi-tenancy)
CREATE OR REPLACE ROW ACCESS POLICY organization_access_policy
  AS (organization_key INT) RETURNS BOOLEAN ->
  CASE 
    WHEN CURRENT_ROLE() = 'ADMIN' THEN TRUE
    WHEN CURRENT_ROLE() = 'ANALYST' THEN 
      organization_key IN (
        SELECT organization_key 
        FROM user_organization_mapping 
        WHERE user_name = CURRENT_USER()
      )
    ELSE FALSE
  END;

-- Apply policy to dimension
ALTER TABLE dimensions.dim_organization 
  ADD ROW ACCESS POLICY organization_access_policy ON (organization_key);

-- ============================================================================
-- SAMPLE QUERIES
-- ============================================================================

-- Top 10 campaigns by ROAS
-- SELECT * FROM vw_campaign_roi
-- WHERE full_date >= DATEADD(month, -1, CURRENT_DATE())
-- ORDER BY roas DESC
-- LIMIT 10;

-- Month-over-month growth
-- SELECT 
--   year,
--   month,
--   SUM(total_revenue) AS monthly_revenue,
--   LAG(SUM(total_revenue)) OVER (ORDER BY year, month) AS prev_month_revenue,
--   ((SUM(total_revenue) - LAG(SUM(total_revenue)) OVER (ORDER BY year, month)) 
--     / LAG(SUM(total_revenue)) OVER (ORDER BY year, month)) * 100 AS mom_growth_percent
-- FROM vw_campaign_roi
-- GROUP BY year, month
-- ORDER BY year DESC, month DESC;

-- Segment attribution analysis
-- SELECT * FROM vw_segment_ranking
-- WHERE revenue_rank <= 5
-- ORDER BY avg_roas DESC;

