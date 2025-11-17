# Entity-Relationship Diagrams

## Core Operational Database (PostgreSQL)

### Organizations & Users Domain

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          ORGANIZATIONS & USERS                          │
└─────────────────────────────────────────────────────────────────────────┘

                    organizations
                   ┌────────────────┐
                   │ id (PK)        │
                   │ uuid           │
                   │ name           │
                   │ slug (UK)      │
                   │ tier           │
                   │ status         │
                   │ settings (JSON)│
                   │ created_at     │
                   └────────┬───────┘
                            │
                ┌───────────┴───────────┐
                │ 1:N                   │ 1:N
                ↓                       ↓
         ┌──────────────┐        ┌──────────────┐
         │ users        │        │ social_accts │
         │──────────────│        │──────────────│
         │ id (PK)      │        │ id (PK)      │
         │ org_id (FK)  │        │ org_id (FK)  │
         │ email (UK)   │        │ platform     │
         │ password_hash│        │ platform_id  │
         │ role         │        │ username     │
         │ permissions  │        │ profile_data │
         │ oauth_data   │        │ sync_status  │
         │ created_at   │        │ credentials  │
         └──────┬───────┘        └──────┬───────┘
                │ 1:N                   │ 1:N
                ↓                       ↓
         ┌──────────────┐        ┌──────────────┐
         │ api_keys     │        │ followers    │
         │──────────────│        │──────────────│
         │ id (PK)      │        │ id (PK)      │
         │ user_id (FK) │        │ social_acct  │
         │ org_id (FK)  │        │   _id (FK)   │
         │ key_hash     │        │ platform     │
         │ scopes       │        │ platform_id  │
         │ expires_at   │        │ username     │
         └──────────────┘        │ profile_data │
                                 │ enriched_data│
                                 │ engagement   │
                                 │ follow_status│
                                 │ created_at   │
                                 └──────────────┘
```

### Followers & Segmentation Domain

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    FOLLOWERS & AI SEGMENTATION                          │
└─────────────────────────────────────────────────────────────────────────┘

            followers                      ai_segments
          ┌────────────┐                 ┌─────────────┐
          │ id (PK)    │                 │ id (PK)     │
          │ social_id  │                 │ org_id (FK) │
          │ platform   │                 │ name        │
          │ username   │                 │ description │
          │ profile    │                 │ type        │
          │ enriched   │                 │ criteria    │
          │ engagement │                 │ persona     │
          └─────┬──────┘                 └──────┬──────┘
                │                               │
                │          N:M                  │
                └───────────┬───────────────────┘
                            ↓
                  ┌───────────────────┐
                  │ segment_members   │
                  │───────────────────│
                  │ id (PK)           │
                  │ segment_id (FK)   │
                  │ follower_id (FK)  │
                  │ match_score       │
                  │ assigned_at       │
                  └───────────────────┘
                            │
                            ↓
                  ┌───────────────────┐
                  │ model_predictions │
                  │───────────────────│
                  │ id (PK)           │
                  │ model_id (FK)     │
                  │ follower_id (FK)  │
                  │ prediction_type   │
                  │ prediction_value  │
                  │ confidence_score  │
                  └───────────────────┘
```

### Campaigns & Ads Domain

```
┌─────────────────────────────────────────────────────────────────────────┐
│                       CAMPAIGNS & ADVERTISING                           │
└─────────────────────────────────────────────────────────────────────────┘

                      campaigns
                    ┌───────────────┐
                    │ id (PK)       │
                    │ org_id (FK)   │
                    │ name          │
                    │ objective     │
                    │ platforms []  │
                    │ target_segs []│
                    │ budget        │
                    │ schedule      │
                    │ status        │
                    │ metrics       │
                    └───────┬───────┘
                            │ 1:N
                ┌───────────┴───────────┐
                ↓                       ↓
          ┌──────────────┐       ┌──────────────┐
          │ ad_groups    │       │ ad_creatives │
          │──────────────│       │──────────────│
          │ id (PK)      │       │ id (PK)      │
          │ campaign_id  │       │ campaign_id  │
          │   (FK)       │←──────│   (FK)       │
          │ name         │ 1:N   │ ad_group_id  │
          │ targeting    │       │   (FK)       │
          │ bid_amount   │       │ name         │
          │ status       │       │ format       │
          └──────────────┘       │ headline     │
                                 │ body         │
                                 │ cta          │
                                 │ media_urls[] │
                                 │ ai_generated │
                                 │ ai_prompt    │
                                 │ performance  │
                                 └──────────────┘

          References:
          campaigns.target_segs → ai_segments.id (Array FK)
```

### AI Models Domain

```
┌─────────────────────────────────────────────────────────────────────────┐
│                            AI MODELS                                    │
└─────────────────────────────────────────────────────────────────────────┘

                      ai_models
                    ┌────────────────┐
                    │ id (PK)        │
                    │ name           │
                    │ model_type     │
                    │ framework      │
                    │ version        │
                    │ artifact_url   │
                    │ training_data  │
                    │ metrics        │
                    │ status         │
                    └────────┬───────┘
                             │ 1:N
                             ↓
                  ┌─────────────────────┐
                  │ model_predictions   │
                  │─────────────────────│
                  │ id (PK)             │
                  │ model_id (FK)       │
                  │ follower_id (FK)    │
                  │ prediction_type     │
                  │ prediction_value    │
                  │ confidence_score    │
                  │ predicted_at        │
                  └─────────────────────┘

          Note: Training data stored in MongoDB
```

## Time-Series Database (TimescaleDB)

### Metrics Hypertables

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         TIME-SERIES METRICS                             │
└─────────────────────────────────────────────────────────────────────────┘

    follower_engagement                 campaign_metrics
   ┌────────────────────┐             ┌────────────────────┐
   │ time (PK)          │             │ time (PK)          │
   │ follower_id        │             │ campaign_id        │
   │ social_account_id  │             │ ad_creative_id     │
   │ metric_type        │             │ platform           │
   │ value              │             │ impressions        │
   │ platform           │             │ clicks             │
   │ post_id            │             │ conversions        │
   │ metadata           │             │ spend              │
   └──────┬─────────────┘             │ revenue            │
          │                           │ engagement_metrics │
          │ Continuous Aggregates     │ targeting_dims     │
          ↓                           └──────┬─────────────┘
   ┌────────────────────┐                   │
   │ follower_eng_hourly│                   │ Continuous Aggregates
   │────────────────────│                   ↓
   │ hour (bucketed)    │             ┌────────────────────┐
   │ follower_id        │             │ campaign_met_hourly│
   │ metric_type        │             │────────────────────│
   │ avg_value          │             │ hour (bucketed)    │
   │ max_value          │             │ campaign_id        │
   │ sum_value          │             │ total_impressions  │
   │ event_count        │             │ total_clicks       │
   └────────────────────┘             │ total_spend        │
          │                           │ ctr, cpc, cpm      │
          ↓                           │ roas               │
   ┌────────────────────┐             └────────────────────┘
   │ follower_eng_daily │                   │
   │────────────────────│                   ↓
   │ day (bucketed)     │             ┌────────────────────┐
   │ follower_id        │             │ campaign_met_daily │
   │ metric_type        │             │────────────────────│
   │ aggregates         │             │ day (bucketed)     │
   │ percentiles        │             │ campaign_id        │
   └────────────────────┘             │ daily_aggregates   │
                                      │ calculated_metrics │
                                      └────────────────────┘

    behavioral_events                ai_model_metrics
   ┌────────────────────┐           ┌────────────────────┐
   │ time (PK)          │           │ time (PK)          │
   │ follower_id        │           │ model_id           │
   │ event_type         │           │ model_version      │
   │ event_category     │           │ predictions_count  │
   │ properties         │           │ accuracy           │
   │ session_id         │           │ precision, recall  │
   │ platform           │           │ f1_score           │
   └────────────────────┘           │ inference_time     │
                                    │ error_count        │
                                    └────────────────────┘

  Partitioning: All tables partitioned by time (1-day chunks)
  Compression: Enabled after 7 days (10-20x reduction)
  Retention: Varies by table (7-730 days)
```

## Document Store (MongoDB)

### Collections Schema

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        MONGODB COLLECTIONS                              │
└─────────────────────────────────────────────────────────────────────────┘

  social_platform_raw              ai_training_data
  {                                {
    _id,                             _id,
    social_account_id,               dataset_name,
    platform,                        model_type,
    data_type,                       source_filters: {},
    raw_payload: {                   records: [
      // Flexible schema            {
      // Platform API response        follower_id,
    },                                 features: {},
    fetched_at,                        label
    processed: bool,                 }
    metadata: {}                     ],
  }                                  statistics: {},
                                     train_split: [],
  ↓ References                       validation_split: [],
  social_accounts.id (PostgreSQL)    test_split: []
                                   }

  ai_persona_analysis              ai_generated_content
  {                                {
    _id,                             _id,
    segment_id,                      campaign_id,
    persona_profile: {               ad_creative_id,
      name,                          content_type,
      description,                   generated_content: {},
      archetype                      prompt_used,
    },                               model_used,
    demographics: {},                target_segment,
    psychographics: {},              performance_metrics: {},
    behavioral_patterns: {},         human_edited: bool,
    interests: [],                   approved: bool,
    brand_affinities: [],            generated_at
    content_recommendations: {},   }
    pain_points: [],
    motivations: [],                ↓ References
    ai_model_used,                  campaigns.id (PostgreSQL)
    confidence_score,               ad_creatives.id (PostgreSQL)
    generated_at
  }

  ↓ References
  ai_segments.id (PostgreSQL)


  model_predictions_history        ab_test_experiments
  {                                {
    _id,                             _id,
    model_id,                        experiment_name,
    model_version,                   campaign_id,
    batch_id,                        hypothesis,
    predictions: [                   variants: [
      {                              {
        follower_id,                   variant_name,
        prediction,                    ad_creative_id,
        confidence,                    traffic_allocation,
        features_used: {}              metrics: {}
      }                              }
    ],                               ],
    inference_metadata: {},          success_metric,
    predicted_at                     results: {},
  }                                  status,
                                     started_at,
                                     completed_at
  TTL: 180 days                    }
```

## Data Warehouse (Snowflake Star Schema)

### Star Schema Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    DATA WAREHOUSE STAR SCHEMA                           │
└─────────────────────────────────────────────────────────────────────────┘

                  DIMENSION TABLES (Surround Facts)

      dim_date          dim_time          dim_organization
     ┌─────────┐       ┌─────────┐       ┌────────────────┐
     │date_key │       │time_key │       │organization_key│
     │full_date│       │hour     │       │org_id          │
     │year     │       │minute   │       │name            │
     │quarter  │       │is_biz_hr│       │tier            │
     │month    │       └─────────┘       │industry        │
     │week     │                         │SCD Type 2      │
     │day_name │                         └────────────────┘
     │is_weekend│
     └─────────┘       dim_platform      dim_campaign
                      ┌────────────┐     ┌──────────────┐
      dim_geography   │platform_key│     │campaign_key  │
     ┌────────────┐   │name        │     │campaign_id   │
     │geo_key     │   │category    │     │org_key (FK)  │
     │country_code│   │parent_co   │     │name          │
     │country_name│   └────────────┘     │objective     │
     │region      │                      │budget        │
     │city_name   │   dim_segment        │SCD Type 2    │
     │lat/long    │  ┌─────────────┐     └──────────────┘
     └────────────┘  │segment_key  │
                     │segment_id   │     dim_ad_creative
      dim_follower   │org_key (FK) │    ┌───────────────┐
     ┌────────────┐  │name         │    │ad_creative_key│
     │follower_key│  │type         │    │ad_creative_id │
     │follower_id │  │persona      │    │campaign_key   │
     │platform_key│  │SCD Type 2   │    │   (FK)        │
     │username    │  └─────────────┘    │format         │
     │demographics│                     │ai_generated   │
     │interests   │                     │SCD Type 2     │
     │engagement  │                     └───────────────┘
     │SCD Type 2  │
     └────────────┘

                         FACT TABLES (Center)

               fact_campaign_performance
              ┌───────────────────────────┐
              │ date_key (FK) ────────────┼─→ dim_date
              │ campaign_key (FK) ────────┼─→ dim_campaign
              │ ad_creative_key (FK) ─────┼─→ dim_ad_creative
              │ platform_key (FK) ────────┼─→ dim_platform
              │ segment_key (FK) ─────────┼─→ dim_segment
              │ geography_key (FK) ───────┼─→ dim_geography
              │                           │
              │ Measures:                 │
              │ impressions               │
              │ clicks                    │
              │ conversions               │
              │ spend                     │
              │ revenue                   │
              │ ctr, cvr, cpc, cpm, cpa   │
              │ roas                      │
              └───────────────────────────┘

               fact_follower_engagement
              ┌───────────────────────────┐
              │ date_key (FK) ────────────┼─→ dim_date
              │ follower_key (FK) ────────┼─→ dim_follower
              │ platform_key (FK) ────────┼─→ dim_platform
              │                           │
              │ Measures:                 │
              │ likes_given               │
              │ comments_given            │
              │ shares_given              │
              │ posts_created             │
              │ engagement_score          │
              └───────────────────────────┘

               fact_segment_performance
              ┌───────────────────────────┐
              │ date_key (FK) ────────────┼─→ dim_date
              │ segment_key (FK) ─────────┼─→ dim_segment
              │ campaign_key (FK) ────────┼─→ dim_campaign
              │                           │
              │ Measures:                 │
              │ targeted_followers        │
              │ reached_followers         │
              │ engaged_followers         │
              │ total_impressions         │
              │ total_spend               │
              │ segment_roas              │
              └───────────────────────────┘
```

### Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         DATA FLOW ARCHITECTURE                          │
└─────────────────────────────────────────────────────────────────────────┘

   OPERATIONAL LAYER              ANALYTICS LAYER           SERVING LAYER
  ┌──────────────────┐          ┌──────────────┐         ┌──────────────┐
  │  PostgreSQL      │          │ TimescaleDB  │         │   Redis      │
  │  (Transactional) │          │ (Time-Series)│         │   (Cache)    │
  │                  │          │              │         │              │
  │ • Users          │          │ • Engagement │         │ • Sessions   │
  │ • Campaigns      │          │ • Metrics    │         │ • Aggregates │
  │ • Followers      │          │ • Events     │         │ • Leaderboard│
  │ • Segments       │          │              │         │              │
  └────────┬─────────┘          └──────┬───────┘         └──────┬───────┘
           │                           │                        │
           │                           │                        │
  ┌────────▼─────────┐          ┌──────▼───────┐         ┌──────▼───────┐
  │    MongoDB       │          │ Elasticsearch│         │  S3 Storage  │
  │  (Documents)     │          │   (Search)   │         │  (Objects)   │
  │                  │          │              │         │              │
  │ • Raw API data   │          │ • Follower   │         │ • Media      │
  │ • AI personas    │          │   search     │         │ • Exports    │
  │ • Training data  │          │ • Content    │         │ • Models     │
  │                  │          │   search     │         │              │
  └────────┬─────────┘          └──────────────┘         └──────────────┘
           │                                                     
           │                                                     
           │    ┌──────────────────────────────────────┐        
           │    │         ETL PIPELINE                 │        
           │    │    (Airflow / Prefect / dbt)        │        
           └────┼──→  Extract, Transform, Load  ←──────┤        
                │                                      │        
                └──────────────┬───────────────────────┘        
                               ↓                                
                    ┌──────────────────────┐                    
                    │   Snowflake / BigQuery│                    
                    │   (Data Warehouse)    │                    
                    │                       │                    
                    │ • Star schema         │                    
                    │ • Historical analytics│                    
                    │ • BI reporting        │                    
                    │ • ML feature store    │                    
                    └──────────┬────────────┘                    
                               │                                
                ┌──────────────┴──────────────┐                
                ↓                             ↓                
         ┌─────────────┐              ┌──────────────┐         
         │ BI Tools    │              │ ML Platform  │         
         │             │              │              │         
         │ • Tableau   │              │ • Jupyter    │         
         │ • Looker    │              │ • MLflow     │         
         │ • Metabase  │              │ • SageMaker  │         
         └─────────────┘              └──────────────┘         
```

## Relationships Summary

### Cross-Database References

1. **PostgreSQL → MongoDB**
   - `social_accounts.id` → `social_platform_raw.social_account_id`
   - `ai_segments.id` → `ai_persona_analysis.segment_id`
   - `campaigns.id` → `ai_generated_content.campaign_id`

2. **PostgreSQL → TimescaleDB**
   - `followers.id` → `follower_engagement.follower_id`
   - `campaigns.id` → `campaign_metrics.campaign_id`
   - `ai_models.id` → `ai_model_metrics.model_id`

3. **PostgreSQL → Redis** (Application-level caching)
   - `users.id` → `session:{user_id}`
   - `social_accounts.id` → `stats:account:{account_id}`
   - `campaigns.id` → `metrics:campaign:{campaign_id}`

4. **All Databases → Snowflake** (ETL pipeline)
   - PostgreSQL tables → Dimension tables
   - TimescaleDB metrics → Fact tables
   - MongoDB documents → Enriched dimensions

### Cardinality

- Organization (1) → Users (N)
- Organization (1) → Social Accounts (N)
- Social Account (1) → Followers (N)
- Segment (1) → Followers (N) via segment_members
- Campaign (1) → Ad Groups (N)
- Campaign (1) → Ad Creatives (N)
- AI Model (1) → Predictions (N)

