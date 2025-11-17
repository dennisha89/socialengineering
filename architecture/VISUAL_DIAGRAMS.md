# Visual Architecture Diagrams

## 1. High-Level System Architecture

```
┌────────────────────────────────────────────────────────────────────────────┐
│                              Internet / Users                               │
│                        (Web, Mobile, API Clients)                           │
└────────────────────────────────┬───────────────────────────────────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │    CloudFlare / WAF     │
                    │   DDoS Protection       │
                    └────────────┬────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │    CDN (CloudFront)     │
                    │  Static Assets, Images  │
                    └────────────┬────────────┘
                                 │
┌────────────────────────────────────────────────────────────────────────────┐
│                           API Gateway Layer                                 │
│                              (Kong)                                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │   Auth   │  │   Rate   │  │  Routing │  │   SSL    │  │   CORS   │   │
│  │   Check  │  │ Limiting │  │ & Balance│  │   Term   │  │  Handling│   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└─────────┬──────────┬──────────┬──────────┬──────────┬──────────┬─────────┘
          │          │          │          │          │          │
          ▼          ▼          ▼          ▼          ▼          ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                     Service Mesh (Istio / Linkerd)                       │
│                      mTLS, Circuit Breaking, Retries                     │
└─────────┬──────────┬──────────┬──────────┬──────────┬──────────┬───────┘
          │          │          │          │          │          │
┌─────────▼─────┐┌───▼────┐┌───▼─────┐┌───▼─────┐┌───▼─────┐┌───▼─────┐
│     Auth      ││  User  ││ Social  ││   AI    ││   Ad    ││Campaign │
│   Service     ││Service ││ Integ   ││Process  ││  Gen    ││ Manager │
│  (Keycloak)   ││        ││ Service ││ Engine  ││ Service ││         │
└───────────────┘└────────┘└─────────┘└─────────┘└─────────┘└─────────┘
          │          │          │          │          │          │
          └──────────┴──────────┴──────────┴──────────┴──────────┘
                                 │
                    ┌────────────▼────────────┐
                    │   Message Queue (Kafka) │
                    │   Event Streaming       │
                    └────────────┬────────────┘
                                 │
┌────────────────────────────────────────────────────────────────────────────┐
│                            Data Storage Layer                               │
│                                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │ PostgreSQL  │  │   MongoDB   │  │    Redis    │  │  Vector DB  │     │
│  │  (RDS)      │  │   (Atlas)   │  │ (ElastiCache│  │  (Pinecone) │     │
│  │             │  │             │  │   Cluster)  │  │             │     │
│  │ Users       │  │ Followers   │  │ Sessions    │  │ Embeddings  │     │
│  │ Campaigns   │  │ Posts       │  │ Cache       │  │ Similarity  │     │
│  │ Billing     │  │ Raw Data    │  │ Rate Limits │  │ Search      │     │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘     │
│                                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                       │
│  │     S3      │  │ TimescaleDB │  │  BigQuery   │                       │
│  │ (Storage)   │  │(Time-Series)│  │(Data Warehouse)                     │
│  │             │  │             │  │             │                       │
│  │ Ads/Images  │  │ Analytics   │  │ Historical  │                       │
│  │ Backups     │  │ Metrics     │  │ Analytics   │                       │
│  │ Archives    │  │ Events      │  │ BI Reports  │                       │
│  └─────────────┘  └─────────────┘  └─────────────┘                       │
└────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Microservices Detailed Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                        Authentication Service                             │
│                           (Keycloak / Auth0)                              │
│                                                                           │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐            │
│  │ OAuth 2.0 / OIDC   │  User Auth    │  │  API Keys      │            │
│  │ Flows          │  │  Management   │  │  Management    │            │
│  └────────────────┘  └────────────────┘  └────────────────┘            │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│                   Social Media Integration Service                        │
│                         (Node.js / Express)                               │
│                                                                           │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌──────────┐ │
│  │Instagram  │ │ Twitter/X │ │ Facebook  │ │  TikTok   │ │ LinkedIn │ │
│  │ Connector │ │ Connector │ │ Connector │ │ Connector │ │Connector │ │
│  └─────┬─────┘ └─────┬─────┘ └─────┬─────┘ └─────┬─────┘ └────┬─────┘ │
│        └───────────────┴───────────────┴───────────────┴──────────┘      │
│                                │                                          │
│                   ┌────────────▼────────────┐                            │
│                   │ Rate Limiter (Redis)    │                            │
│                   │ Platform-specific limits│                            │
│                   └────────────┬────────────┘                            │
│                                │                                          │
│                   ┌────────────▼────────────┐                            │
│                   │ Data Normalizer         │                            │
│                   │ Unified schema          │                            │
│                   └────────────┬────────────┘                            │
│                                │                                          │
│                                ▼                                          │
│                        Publish to Kafka                                   │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│                      Data Ingestion Pipeline                              │
│                        (Kafka Streams)                                    │
│                                                                           │
│  Kafka Topics:                                                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │
│  │follower.raw │  │follower.    │  │ segment.    │  │  campaign.  │   │
│  │             │→ │ analyzed    │→ │ generated   │→ │  events     │   │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘   │
│                                                                           │
│  Consumer Groups:                                                         │
│  • Follower Processor → MongoDB Writer                                   │
│  • AI Analysis Trigger → AI Processing Service                           │
│  • Segment Generator → Segmentation Service                              │
│  • Analytics Aggregator → TimescaleDB Writer                             │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│                        AI Processing Engine                               │
│                        (Python / FastAPI)                                 │
│                                                                           │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │                    NLP Analysis Module                              │ │
│  │  • Sentiment Analysis (VADER, Transformers)                         │ │
│  │  • Topic Modeling (LDA, BERTopic)                                   │ │
│  │  • Named Entity Recognition (spaCy)                                 │ │
│  │  • Interest Extraction (Custom ML Model)                            │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                                                                           │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │                Computer Vision Module                               │ │
│  │  • Profile Picture Analysis (ResNet, EfficientNet)                  │ │
│  │  • Object Detection (YOLO)                                          │ │
│  │  • Scene Classification                                             │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                                                                           │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │             Demographic & Psychographic Inference                   │ │
│  │  • Age/Gender Prediction (ML Classifier)                            │ │
│  │  • Location Inference (Geocoding)                                   │ │
│  │  • Purchase Intent Scoring (Custom Model)                           │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                                                                           │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │                  Embedding Generation                               │ │
│  │  • Text Embeddings (OpenAI, Sentence-BERT)                          │ │
│  │  • Store in Vector DB (Pinecone)                                    │ │
│  └────────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│                      Segmentation Service                                 │
│                        (Python / FastAPI)                                 │
│                                                                           │
│  Input: Segment Criteria (JSON)                                          │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │ {                                                                   │ │
│  │   "interests": ["coffee", "travel"],                                │ │
│  │   "min_engagement_rate": 0.05,                                      │ │
│  │   "demographics": {"age_range": "25-34"},                           │ │
│  │   "location": {"countries": ["US", "CA"]}                           │ │
│  │ }                                                                    │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                                │                                          │
│                                ▼                                          │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │              Query Builder                                          │ │
│  │  • MongoDB aggregation pipeline                                     │ │
│  │  • Vector similarity search (if semantic)                           │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                                │                                          │
│                                ▼                                          │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │           Clustering Algorithm (K-Means, DBSCAN)                    │ │
│  │  • Group similar followers                                          │ │
│  │  • Identify representative samples                                  │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                                │                                          │
│                                ▼                                          │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │               Persona Generation (LLM)                              │ │
│  │  • Call GPT-4 / Claude with cluster data                            │ │
│  │  • Generate persona descriptions                                    │ │
│  │  • Extract marketing insights                                       │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                                │                                          │
│                                ▼                                          │
│  Output: Segments + Personas → PostgreSQL                                │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│                       Ad Generation Service                               │
│                        (Python / FastAPI)                                 │
│                                                                           │
│  Input: Creative Brief + Persona Data                                    │
│                                │                                          │
│                                ▼                                          │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │                  Prompt Engineering                                 │ │
│  │  • Construct LLM prompt with:                                       │ │
│  │    - Persona details (demographics, interests, pain points)         │ │
│  │    - Product/service info                                           │ │
│  │    - Brand guidelines                                               │ │
│  │    - Platform specifications (Instagram, Facebook, etc.)            │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                                │                                          │
│                                ▼                                          │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │              LLM API Call (GPT-4 / Claude)                          │ │
│  │  • Generate ad headline                                             │ │
│  │  • Generate ad body text                                            │ │
│  │  • Generate CTA (Call to Action)                                    │ │
│  │  • Generate 3 variants for A/B testing                              │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                                │                                          │
│                                ▼                                          │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │         Image Generation (DALL-E / Stable Diffusion)                │ │
│  │  • Generate prompt from persona + brief                             │ │
│  │  • Call image generation API                                        │ │
│  │  • Resize for platform (Instagram: 1080x1080, etc.)                 │ │
│  │  • Overlay logo/branding                                            │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                                │                                          │
│                                ▼                                          │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │                    Post-processing                                  │ │
│  │  • Upload images to S3                                              │ │
│  │  • Store metadata in PostgreSQL                                     │ │
│  │  • Notify user via WebSocket                                        │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                                │                                          │
│                                ▼                                          │
│  Output: Generated Ads (text + images) → User Dashboard                  │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│                     Campaign Management Service                           │
│                           (Go / Gin)                                      │
│                                                                           │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐            │
│  │   Campaign     │  │   Targeting    │  │   Budget       │            │
│  │   Creation     │→ │   Rules        │→ │   Management   │            │
│  └────────────────┘  └────────────────┘  └────────────────┘            │
│                                │                                          │
│                                ▼                                          │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │           Social Media Ad Platform APIs                             │ │
│  │  • Facebook Ads API → Create ad sets, ads                           │ │
│  │  • Instagram Ads API → Placement, scheduling                        │ │
│  │  • Twitter Ads API → Campaign setup                                 │ │
│  │  • TikTok Ads API → Creative upload                                 │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                                │                                          │
│                                ▼                                          │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │              Webhook Handler (Platform Events)                      │ │
│  │  • Ad approved / rejected                                           │ │
│  │  • Campaign started / paused / completed                            │ │
│  │  • Budget alerts                                                    │ │
│  └────────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│                        Analytics Service                                  │
│                    (Python / Spark / ClickHouse)                          │
│                                                                           │
│  Real-time Pipeline (Kafka Streams):                                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │
│  │ Engagement  │→ │ Aggregate   │→ │  Calculate  │→ │   Store     │   │
│  │  Events     │  │  Metrics    │  │  Derived    │  │ TimescaleDB │   │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘   │
│                                                                           │
│  Batch Pipeline (Airflow DAGs):                                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │
│  │   Extract   │→ │  Transform  │→ │    Load     │→ │   BigQuery  │   │
│  │(PostgreSQL) │  │   (Spark)   │  │  (ETL/ELT)  │  │(Warehouse)  │   │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘   │
│                                                                           │
│  Metrics Calculated:                                                      │
│  • CTR (Click-through Rate) = Clicks / Impressions                       │
│  • CPC (Cost per Click) = Spend / Clicks                                 │
│  • CPA (Cost per Acquisition) = Spend / Conversions                      │
│  • ROAS (Return on Ad Spend) = Revenue / Spend                           │
│  • Engagement Rate = (Likes + Comments + Shares) / Impressions           │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Data Flow: Follower Analysis (End-to-End)

```
┌───────────────────────────────────────────────────────────────────────────┐
│ Step 1: User Connects Instagram Account                                   │
└───────────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
        User clicks "Connect Instagram" on Dashboard
                                │
                                ▼
┌───────────────────────────────────────────────────────────────────────────┐
│ POST /api/v1/social-accounts/connect                                      │
│ { "platform": "instagram", "redirect_uri": "..." }                        │
└───────────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌───────────────────────────────────────────────────────────────────────────┐
│ Social Integration Service generates OAuth URL                            │
│ → Redirect user to Instagram OAuth consent page                           │
└───────────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
        User approves permissions on Instagram
                                │
                                ▼
┌───────────────────────────────────────────────────────────────────────────┐
│ Instagram redirects back with authorization code                          │
│ → POST /api/v1/social-accounts/callback                                   │
└───────────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌───────────────────────────────────────────────────────────────────────────┐
│ Social Integration Service:                                               │
│ 1. Exchange code for access token                                         │
│ 2. Encrypt and store tokens (PostgreSQL)                                  │
│ 3. Store account metadata (username, profile pic, etc.)                   │
└───────────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌───────────────────────────────────────────────────────────────────────────┐
│ Step 2: Trigger Follower Sync                                             │
└───────────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
        POST /api/v1/social-accounts/{id}/sync
                                │
                                ▼
┌───────────────────────────────────────────────────────────────────────────┐
│ Social Integration Service:                                               │
│ 1. Create job record (status: queued)                                     │
│ 2. Publish job to Kafka topic: "follower.sync.requested"                  │
│ 3. Return job_id to user (202 Accepted)                                   │
└───────────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌───────────────────────────────────────────────────────────────────────────┐
│ Follower Sync Worker (Kafka Consumer):                                    │
│                                                                            │
│ LOOP for each follower (paginated):                                       │
│   1. Check rate limit (Redis)                                             │
│   2. If limit OK:                                                          │
│      • GET /instagram/api/followers?cursor=xyz                            │
│      • Extract follower data                                              │
│      • Publish to Kafka: "follower.raw"                                   │
│   3. Else:                                                                 │
│      • Sleep until rate limit resets                                      │
│                                                                            │
│ Update job progress (25%, 50%, 75%, 100%)                                 │
└───────────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌───────────────────────────────────────────────────────────────────────────┐
│ Step 3: Data Ingestion & Storage                                          │
└───────────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌───────────────────────────────────────────────────────────────────────────┐
│ Data Ingestion Worker (Kafka Consumer of "follower.raw"):                 │
│                                                                            │
│ 1. Validate data schema                                                   │
│ 2. Deduplicate (check if follower already exists)                         │
│ 3. Enrich data (add timestamp, account_id, etc.)                          │
│ 4. Store in MongoDB:                                                      │
│    db.followers.updateOne(                                                │
│      { platform_follower_id: "123", social_account_id: "uuid" },         │
│      { $set: follower_data },                                             │
│      { upsert: true }                                                     │
│    )                                                                       │
│ 5. Publish to Kafka: "follower.analysis.requested"                        │
└───────────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌───────────────────────────────────────────────────────────────────────────┐
│ Step 4: AI Analysis                                                        │
└───────────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌───────────────────────────────────────────────────────────────────────────┐
│ AI Processing Worker (Kafka Consumer of "follower.analysis.requested"):   │
│                                                                            │
│ 1. Retrieve follower data from MongoDB                                    │
│                                                                            │
│ 2. NLP Analysis:                                                           │
│    • Extract interests from bio (spaCy NER + custom model)                │
│      "Coffee lover ☕ Travel 🌍" → ["coffee", "travel"]                   │
│    • Sentiment analysis (positive/negative/neutral)                       │
│    • Language detection                                                   │
│                                                                            │
│ 3. Computer Vision (if profile picture available):                        │
│    • Download image from URL                                              │
│    • Run CNN model (ResNet) → ["outdoor", "person", "beach"]             │
│                                                                            │
│ 4. Demographic Inference:                                                 │
│    • Age/gender prediction (ML classifier)                                │
│    • Location inference (from bio, posts)                                 │
│                                                                            │
│ 5. Generate Embeddings:                                                   │
│    • Combine bio + interests → text                                       │
│    • Call OpenAI Embeddings API → 768-dim vector                          │
│    • Store in Vector DB (Pinecone)                                        │
│                                                                            │
│ 6. Calculate Purchase Intent Scores:                                      │
│    • Run ML model (trained on historical conversion data)                 │
│    • Score 0-1 for each product category                                  │
│                                                                            │
│ 7. Update MongoDB with analysis results:                                  │
│    db.followers.updateOne(                                                │
│      { _id: follower_id },                                                │
│      { $set: {                                                            │
│          "analysis": {                                                    │
│            "interests": [...],                                            │
│            "demographics": {...},                                         │
│            "purchase_intent": [...]                                       │
│          },                                                               │
│          "analyzed_at": now()                                             │
│        }                                                                  │
│      }                                                                    │
│    )                                                                       │
│                                                                            │
│ 8. Publish to Kafka: "follower.analyzed"                                  │
└───────────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌───────────────────────────────────────────────────────────────────────────┐
│ Step 5: Update User Dashboard (Real-time)                                 │
└───────────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌───────────────────────────────────────────────────────────────────────────┐
│ WebSocket Service (Kafka Consumer of "follower.analyzed"):                │
│                                                                            │
│ 1. Determine which user owns this follower                                │
│ 2. Check if user has active WebSocket connection                          │
│ 3. If yes, send update:                                                   │
│    ws.send({                                                              │
│      "event": "follower_analyzed",                                        │
│      "data": {                                                            │
│        "follower_id": "...",                                              │
│        "progress": {                                                      │
│          "total": 5420,                                                   │
│          "analyzed": 3250,                                                │
│          "percentage": 60                                                 │
│        }                                                                  │
│      }                                                                    │
│    })                                                                     │
│                                                                            │
│ 4. Frontend updates progress bar in real-time                             │
└───────────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌───────────────────────────────────────────────────────────────────────────┐
│ Step 6: Automatic Segmentation (Optional Trigger)                         │
└───────────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌───────────────────────────────────────────────────────────────────────────┐
│ When sync completes (all followers analyzed):                             │
│                                                                            │
│ Segmentation Service:                                                     │
│ 1. Retrieve all analyzed followers for account                            │
│ 2. Run clustering algorithm (K-Means on embeddings)                       │
│ 3. Identify natural segments (e.g., 5 clusters)                           │
│ 4. For each cluster:                                                      │
│    • Calculate cluster statistics                                         │
│    • Identify representative followers                                    │
│    • Generate persona (LLM call)                                          │
│ 5. Store segments + personas in PostgreSQL                                │
│ 6. Notify user: "Your follower analysis is complete. 5 segments found."   │
└───────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Data Flow: Ad Generation

```
┌───────────────────────────────────────────────────────────────────────────┐
│ User creates campaign and requests ad generation                          │
└───────────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
        POST /api/v1/campaigns/{id}/ads/generate
        {
          "num_variants": 3,
          "type": "image",
          "creative_brief": {
            "product_name": "Fall Seasonal Blend Coffee",
            "key_features": ["organic", "small-batch", "cinnamon spice"],
            "tone": "warm, inviting, premium"
          },
          "brand_guidelines": {
            "colors": ["#8B4513", "#D2691E"],
            "logo_url": "https://s3.../logo.png"
          },
          "personalization": { "use_persona": true }
        }
                                │
                                ▼
┌───────────────────────────────────────────────────────────────────────────┐
│ Ad Generation Service:                                                     │
│                                                                            │
│ 1. Retrieve campaign details from PostgreSQL                              │
│ 2. Retrieve persona data (demographics, interests, pain points)           │
│                                                                            │
│ 3. Construct LLM Prompt:                                                  │
│    """                                                                     │
│    You are a marketing copywriter. Generate 3 ad variants for:            │
│                                                                            │
│    Product: Fall Seasonal Blend Coffee                                    │
│    Features: Organic, small-batch, cinnamon spice                         │
│    Tone: Warm, inviting, premium                                          │
│                                                                            │
│    Target Audience Persona:                                               │
│    - Age: 25-34                                                            │
│    - Interests: Coffee, wellness, sustainability                          │
│    - Pain Points: Inconsistent coffee quality, high prices                │
│    - Goals: Find premium coffee for daily routine                         │
│                                                                            │
│    Platform: Instagram Feed                                               │
│    Format: Square image (1080x1080) + caption                             │
│                                                                            │
│    Generate:                                                               │
│    1. Headline (max 40 chars)                                             │
│    2. Body text (max 125 chars)                                           │
│    3. Call-to-action (e.g., "Shop Now", "Learn More")                     │
│                                                                            │
│    Output as JSON with 3 variants (A, B, C).                              │
│    """                                                                     │
│                                                                            │
│ 4. Call LLM API (GPT-4 / Claude):                                         │
│    response = openai.chat.completions.create(                             │
│      model="gpt-4",                                                       │
│      messages=[{"role": "user", "content": prompt}],                      │
│      response_format={"type": "json_object"}                              │
│    )                                                                       │
│                                                                            │
│ 5. Parse LLM Response:                                                    │
│    {                                                                       │
│      "variants": [                                                        │
│        {                                                                  │
│          "variant": "A",                                                  │
│          "headline": "Fall in Love with Every Sip",                       │
│          "body": "Organic, small-batch coffee with cinnamon warmth...",   │
│          "cta": "Shop Now"                                                │
│        },                                                                 │
│        { ... variant B ... },                                             │
│        { ... variant C ... }                                              │
│      ]                                                                     │
│    }                                                                       │
└───────────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌───────────────────────────────────────────────────────────────────────────┐
│ Image Generation:                                                          │
│                                                                            │
│ FOR EACH variant:                                                          │
│   1. Construct image prompt:                                              │
│      """                                                                   │
│      A warm and inviting photo of a cup of coffee with cinnamon stick,    │
│      cozy autumn background with falling leaves, professional product     │
│      photography, premium aesthetic, natural lighting, earthy tones       │
│      #8B4513 and #D2691E color palette                                    │
│      """                                                                   │
│                                                                            │
│   2. Call DALL-E 3 API:                                                   │
│      response = openai.images.generate(                                   │
│        model="dall-e-3",                                                  │
│        prompt=image_prompt,                                               │
│        size="1024x1024",                                                  │
│        quality="hd",                                                      │
│        n=1                                                                │
│      )                                                                     │
│                                                                            │
│   3. Download generated image                                             │
│                                                                            │
│   4. Post-process image:                                                  │
│      • Resize to 1080x1080 (Instagram feed)                               │
│      • Overlay brand logo (bottom right corner)                           │
│      • Apply color correction (match brand colors)                        │
│      • Compress for web (JPEG, quality 85)                                │
│                                                                            │
│   5. Upload to S3:                                                        │
│      s3.upload_file(                                                      │
│        "processed_image.jpg",                                             │
│        bucket="platform-ads",                                             │
│        key=f"campaigns/{campaign_id}/ads/{ad_id}/image_A.jpg"            │
│      )                                                                     │
│                                                                            │
│   6. Generate thumbnail (preview):                                        │
│      • Resize to 300x300                                                  │
│      • Upload to S3                                                       │
└───────────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌───────────────────────────────────────────────────────────────────────────┐
│ Store Ad Records:                                                          │
│                                                                            │
│ INSERT INTO ads (campaign_id, name, type, headline, body_text, cta_text, │
│                  media_urls, thumbnail_url, generated_by, model_used,     │
│                  variant_group, variant_name, status)                     │
│ VALUES                                                                     │
│   (campaign_id, 'Fall Blend - Variant A', 'image', 'Fall in Love...',    │
│    'https://s3.../image_A.jpg', 'https://s3.../thumb_A.jpg',             │
│    'ai_generated', 'gpt-4 + dalle-3', 'fall_blend_001', 'A', 'draft'),   │
│                                                                            │
│   (campaign_id, 'Fall Blend - Variant B', ...),                           │
│   (campaign_id, 'Fall Blend - Variant C', ...)                            │
└───────────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌───────────────────────────────────────────────────────────────────────────┐
│ Notify User (WebSocket):                                                  │
│                                                                            │
│ ws.send({                                                                 │
│   "event": "ads_generated",                                               │
│   "data": {                                                               │
│     "campaign_id": "uuid",                                                │
│     "ads": [                                                              │
│       {                                                                   │
│         "id": "ad_uuid_A",                                                │
│         "variant": "A",                                                   │
│         "preview_url": "https://s3.../thumb_A.jpg"                        │
│       },                                                                  │
│       { ... variant B ... },                                              │
│       { ... variant C ... }                                               │
│     ]                                                                     │
│   }                                                                       │
│ })                                                                        │
└───────────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
        User reviews ads on dashboard, approves/edits, launches campaign
```

---

## 5. Security Architecture Layers

```
┌────────────────────────────────────────────────────────────────────────────┐
│                          Layer 1: Perimeter                                 │
│                                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   DDoS       │  │     WAF      │  │  Rate        │  │   Geo        │  │
│  │ Protection   │  │  (ModSecurity│  │  Limiting    │  │  Blocking    │  │
│  │ (CloudFlare) │  │   OWASP)     │  │              │  │  (if needed) │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘  │
│                                                                             │
│  Threats Mitigated:                                                         │
│  ✓ Volumetric DDoS attacks                                                 │
│  ✓ SQL injection, XSS, CSRF                                                │
│  ✓ Brute force attacks                                                     │
│  ✓ Malicious traffic from high-risk regions                                │
└────────────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌────────────────────────────────────────────────────────────────────────────┐
│                          Layer 2: Network                                   │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐ │
│  │                     VPC (Virtual Private Cloud)                       │ │
│  │                                                                       │ │
│  │  ┌────────────────┐         ┌────────────────┐                      │ │
│  │  │ Public Subnet  │         │ Private Subnet │                      │ │
│  │  │ (Load Balancer)│────────▶│ (EKS Nodes,    │                      │ │
│  │  │                │         │  Databases)    │                      │ │
│  │  └────────────────┘         └────────────────┘                      │ │
│  │                                      │                               │ │
│  │                             ┌────────▼────────┐                      │ │
│  │                             │  NAT Gateway    │                      │ │
│  │                             │  (Outbound)     │                      │ │
│  │                             └─────────────────┘                      │ │
│  └───────────────────────────────────────────────────────────────────────┘ │
│                                                                             │
│  Security Groups:                                                           │
│  • EKS Nodes: Only allow traffic from ALB                                  │
│  • Databases: Only allow traffic from EKS nodes                            │
│  • No direct internet access to private subnets                            │
│                                                                             │
│  Service Mesh (Istio):                                                     │
│  • mTLS between all services (encrypted)                                   │
│  • Certificate rotation every 24 hours                                     │
│  • Zero Trust: Every request authenticated                                 │
└────────────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌────────────────────────────────────────────────────────────────────────────┐
│                       Layer 3: Application                                  │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐ │
│  │                    API Gateway (Kong)                                 │ │
│  │                                                                       │ │
│  │  1. JWT Validation ─────────────────┐                                │ │
│  │     • Verify signature               │                                │ │
│  │     • Check expiration               │                                │ │
│  │     • Extract user claims            │                                │ │
│  │                                      │                                │ │
│  │  2. RBAC Authorization ◀─────────────┘                                │ │
│  │     • Check user roles                                                │ │
│  │     • Verify permissions                                              │ │
│  │     • Enforce resource ownership                                      │ │
│  │                                                                       │ │
│  │  3. Input Validation                                                  │ │
│  │     • JSON schema validation                                          │ │
│  │     • Type checking                                                   │ │
│  │     • Size limits                                                     │ │
│  │                                                                       │ │
│  │  4. Output Encoding                                                   │ │
│  │     • HTML entity escaping                                            │ │
│  │     • JSON sanitization                                               │ │
│  │     • Content-Type headers                                            │ │
│  └──────────────────────────────────────────────────────────────────────┘ │
│                                                                             │
│  Each Microservice:                                                         │
│  • Additional input validation (defense in depth)                          │
│  • SQL parameterization (no string concatenation)                          │
│  • Least privilege database credentials                                    │
│  • No secrets in code (loaded from Vault)                                  │
└────────────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌────────────────────────────────────────────────────────────────────────────┐
│                          Layer 4: Data                                      │
│                                                                             │
│  Encryption at Rest:                                                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  PostgreSQL  │  │   MongoDB    │  │    Redis     │  │      S3      │  │
│  │  (RDS with   │  │  (Atlas with │  │ (Encryption  │  │ (SSE-KMS)    │  │
│  │   TDE)       │  │  encryption) │  │   enabled)   │  │              │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘  │
│                                                                             │
│  Encryption in Transit:                                                     │
│  • TLS 1.3 for all database connections                                    │
│  • Certificate pinning for critical services                               │
│                                                                             │
│  Sensitive Field Encryption (Application-level):                           │
│  • Social media tokens: AES-256-GCM                                        │
│  • User PII: AES-256-GCM                                                   │
│  • Keys stored in AWS KMS                                                  │
│  • Key rotation: Every 90 days                                             │
│                                                                             │
│  Backup Encryption:                                                         │
│  • All backups encrypted before upload                                     │
│  • Stored in separate AWS account (isolation)                              │
│  • Access logged and monitored                                             │
└────────────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌────────────────────────────────────────────────────────────────────────────┐
│                    Layer 5: Monitoring & Response                           │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐ │
│  │                       SIEM (ELK Stack)                                │ │
│  │                                                                       │ │
│  │  Collect:                                                             │ │
│  │  • Application logs (structured JSON)                                │ │
│  │  • Access logs (who, what, when, where)                              │ │
│  │  • Authentication attempts (success/failure)                         │ │
│  │  • Database queries (slow query log)                                 │ │
│  │  • System events (SSH logins, sudo commands)                         │ │
│  │                                                                       │ │
│  │  Analyze:                                                             │ │
│  │  • Anomaly detection (ML-based)                                      │ │
│  │  • Rule-based alerts (e.g., >5 failed logins)                        │ │
│  │  • Correlation of events                                             │ │
│  │                                                                       │ │
│  │  Alert:                                                               │ │
│  │  • Critical: PagerDuty (immediate escalation)                        │ │
│  │  • Warning: Slack (investigate within 1 hour)                        │ │
│  │  • Info: Email (daily digest)                                        │ │
│  └──────────────────────────────────────────────────────────────────────┘ │
│                                                                             │
│  Intrusion Detection:                                                       │
│  • Falco (container runtime security)                                      │
│  • Suricata (network IDS)                                                  │
│  • Automated response: Block IPs, isolate pods                             │
│                                                                             │
│  Incident Response Plan:                                                    │
│  1. Detection: SIEM alert triggers                                         │
│  2. Containment: Isolate affected systems                                  │
│  3. Eradication: Remove threat, patch vulnerabilities                      │
│  4. Recovery: Restore from clean backups                                   │
│  5. Post-mortem: Document lessons learned                                  │
└────────────────────────────────────────────────────────────────────────────┘
```

---

## 6. Kubernetes Cluster Architecture

```
┌────────────────────────────────────────────────────────────────────────────┐
│                      EKS Cluster (us-east-1)                                │
│                    Kubernetes Version: 1.28                                 │
└────────────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────────────┐
│                         Control Plane (Managed by AWS)                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │
│  │ API Server  │  │  Scheduler  │  │ Controller  │  │    etcd     │      │
│  │             │  │             │  │  Manager    │  │  (State)    │      │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘      │
└────────────────────────────────────────────────────────────────────────────┘
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        │                           │                           │
┌───────▼────────┐        ┌─────────▼────────┐       ┌─────────▼────────┐
│ Availability   │        │ Availability     │       │ Availability     │
│   Zone A       │        │   Zone B         │       │   Zone C         │
│                │        │                  │       │                  │
│ ┌────────────┐ │        │ ┌────────────┐   │       │ ┌────────────┐   │
│ │ Node Group │ │        │ │ Node Group │   │       │ │ Node Group │   │
│ │  General   │ │        │ │  General   │   │       │ │  General   │   │
│ │ (t3.xlarge)│ │        │ │ (t3.xlarge)│   │       │ │ (t3.xlarge)│   │
│ └────────────┘ │        │ └────────────┘   │       │ └────────────┘   │
│                │        │                  │       │                  │
│ ┌────────────┐ │        │ ┌────────────┐   │       │                  │
│ │ Node Group │ │        │ │ Node Group │   │       │                  │
│ │  AI/GPU    │ │        │ │  AI/GPU    │   │       │                  │
│ │(g5.2xlarge)│ │        │ │(g5.2xlarge)│   │       │                  │
│ └────────────┘ │        │ └────────────┘   │       │                  │
└────────────────┘        └──────────────────┘       └──────────────────┘

Each Node:
┌────────────────────────────────────────────────────────────────────────────┐
│                                 Worker Node                                 │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐ │
│  │                         Kubelet (Node Agent)                          │ │
│  └──────────────────────────────────────────────────────────────────────┘ │
│                                    │                                        │
│  ┌──────────────────────────────────────────────────────────────────────┐ │
│  │               Container Runtime (containerd)                          │ │
│  └──────────────────────────────────────────────────────────────────────┘ │
│                                    │                                        │
│  ┌───────────────────┬─────────────────────┬────────────────────────────┐ │
│  │   Pod 1           │     Pod 2           │       Pod 3                │ │
│  │ ┌───────────────┐ │   ┌───────────────┐ │     ┌───────────────┐    │ │
│  │ │ App Container │ │   │ App Container │ │     │ App Container │    │ │
│  │ └───────────────┘ │   └───────────────┘ │     └───────────────┘    │ │
│  │ ┌───────────────┐ │   ┌───────────────┐ │     ┌───────────────┐    │ │
│  │ │ Istio Sidecar │ │   │ Istio Sidecar │ │     │ Istio Sidecar │    │ │
│  │ │  (Envoy Proxy)│ │   │  (Envoy Proxy)│ │     │  (Envoy Proxy)│    │ │
│  │ └───────────────┘ │   └───────────────┘ │     └───────────────┘    │ │
│  └───────────────────┴─────────────────────┴────────────────────────────┘ │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐ │
│  │              Kube Proxy (Network Routing)                             │ │
│  └──────────────────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────────────────┘

Namespaces:
┌────────────────────────────────────────────────────────────────────────────┐
│  • kube-system         (System components: CoreDNS, kube-proxy)            │
│  • istio-system        (Service mesh components)                           │
│  • monitoring          (Prometheus, Grafana, Loki)                         │
│  • platform-services   (API Gateway, Auth, User, Billing, Campaign)        │
│  • platform-ai         (AI Processing, Ad Generation, Segmentation)        │
│  • platform-integration(Social Integration Service)                        │
│  • vault               (HashiCorp Vault for secrets)                       │
└────────────────────────────────────────────────────────────────────────────┘

Ingress:
┌────────────────────────────────────────────────────────────────────────────┐
│                   NGINX Ingress Controller / AWS ALB                        │
│                                                                             │
│  api.platform.com ──────────▶ API Gateway Service                          │
│  dashboard.platform.com ─────▶ Frontend (React App)                        │
│  admin.platform.com ──────────▶ Admin Dashboard                            │
└────────────────────────────────────────────────────────────────────────────┘
```

---

This document provides visual representations of the system architecture, data flows, and deployment topology. Use these diagrams as reference when implementing the platform or presenting to stakeholders.

