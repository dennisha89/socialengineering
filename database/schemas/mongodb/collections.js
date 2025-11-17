// ============================================================================
// MongoDB Collections Schema for AI-Powered Follower Intelligence System
// Version: 1.0
// Description: Document store for flexible/unstructured data
// ============================================================================

// ============================================================================
// SOCIAL PLATFORM RAW DATA
// ============================================================================

// Collection: social_platform_raw
// Purpose: Store raw API responses from social platforms
db.createCollection("social_platform_raw", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["social_account_id", "platform", "data_type", "fetched_at"],
      properties: {
        social_account_id: {
          bsonType: "long",
          description: "Reference to PostgreSQL social_accounts.id"
        },
        platform: {
          enum: ["instagram", "twitter", "linkedin", "tiktok", "youtube", "facebook"],
          description: "Social media platform"
        },
        data_type: {
          enum: ["followers", "posts", "stories", "comments", "profile", "insights"],
          description: "Type of data fetched"
        },
        raw_payload: {
          bsonType: "object",
          description: "Complete API response (flexible schema)"
        },
        fetched_at: {
          bsonType: "date",
          description: "Timestamp when data was fetched"
        },
        processed: {
          bsonType: "bool",
          description: "Whether data has been processed into structured tables"
        },
        processing_error: {
          bsonType: "string",
          description: "Error message if processing failed"
        },
        metadata: {
          bsonType: "object",
          description: "Additional metadata (rate limit info, pagination, etc.)"
        }
      }
    }
  }
});

// Indexes
db.social_platform_raw.createIndex({ "social_account_id": 1, "fetched_at": -1 });
db.social_platform_raw.createIndex({ "platform": 1, "data_type": 1 });
db.social_platform_raw.createIndex({ "processed": 1 });

// TTL index: Auto-delete documents older than 90 days
db.social_platform_raw.createIndex(
  { "fetched_at": 1 }, 
  { expireAfterSeconds: 7776000 }  // 90 days
);

// Sample document
db.social_platform_raw.insertOne({
  social_account_id: NumberLong(123),
  platform: "instagram",
  data_type: "followers",
  raw_payload: {
    data: [
      {
        id: "17841400123456789",
        username: "johndoe",
        full_name: "John Doe",
        profile_picture_url: "https://...",
        is_verified: false,
        follower_count: 1250,
        following_count: 543,
        media_count: 87,
        biography: "Tech enthusiast | AI researcher",
        external_url: "https://johndoe.com"
      }
      // ... more followers
    ],
    paging: {
      cursors: {
        before: "QVFIUm...",
        after: "QVFIUm..."
      },
      next: "https://graph.instagram.com/v18.0/..."
    }
  },
  fetched_at: new Date("2024-01-15T10:30:00Z"),
  processed: false,
  metadata: {
    rate_limit_remaining: 200,
    rate_limit_reset: new Date("2024-01-15T11:00:00Z"),
    pagination_cursor: "QVFIUm...",
    batch_number: 1,
    total_records: 50
  }
});

// ============================================================================
// AI TRAINING DATASETS
// ============================================================================

// Collection: ai_training_data
// Purpose: Store datasets used for AI model training
db.createCollection("ai_training_data", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["dataset_name", "created_at", "records"],
      properties: {
        dataset_name: {
          bsonType: "string",
          description: "Unique name for the dataset"
        },
        model_type: {
          enum: ["segmentation", "prediction", "classification", "clustering", "generation"],
          description: "Type of model this dataset is for"
        },
        source_filters: {
          bsonType: "object",
          description: "Filters used to create the dataset",
          properties: {
            platforms: { bsonType: "array" },
            date_range: { bsonType: "object" },
            follower_filters: { bsonType: "object" }
          }
        },
        records: {
          bsonType: "array",
          description: "Training samples",
          items: {
            bsonType: "object",
            required: ["features", "label"],
            properties: {
              follower_id: { bsonType: "long" },
              features: { bsonType: "object" },
              label: {},
              metadata: { bsonType: "object" }
            }
          }
        },
        labels: {
          bsonType: "object",
          description: "Label definitions and mappings"
        },
        statistics: {
          bsonType: "object",
          description: "Dataset statistics (mean, std, distributions)"
        },
        train_split: {
          bsonType: "array",
          description: "Indices for training set"
        },
        validation_split: {
          bsonType: "array",
          description: "Indices for validation set"
        },
        test_split: {
          bsonType: "array",
          description: "Indices for test set"
        },
        created_at: {
          bsonType: "date"
        },
        created_by: {
          bsonType: "long",
          description: "User ID who created the dataset"
        }
      }
    }
  }
});

// Indexes
db.ai_training_data.createIndex({ "dataset_name": 1 }, { unique: true });
db.ai_training_data.createIndex({ "model_type": 1 });
db.ai_training_data.createIndex({ "created_at": -1 });

// Sample document
db.ai_training_data.insertOne({
  dataset_name: "engagement_prediction_v1",
  model_type: "prediction",
  source_filters: {
    platforms: ["instagram", "twitter"],
    date_range: {
      start: new Date("2024-01-01"),
      end: new Date("2024-03-31")
    },
    follower_filters: {
      min_followers: 100,
      engagement_rate: { $gte: 0.01 }
    }
  },
  records: [
    {
      follower_id: NumberLong(12345),
      features: {
        follower_count: 1250,
        following_count: 543,
        posts_count: 87,
        avg_likes: 45.2,
        avg_comments: 3.1,
        account_age_days: 730,
        verified: false,
        engagement_rate: 0.038,
        posting_frequency: 0.12,  // posts per day
        interests: ["technology", "ai", "programming"],
        demographics: {
          age_estimate: 28,
          gender_estimate: "male",
          location_country: "US"
        }
      },
      label: 0.65,  // Target: predicted engagement rate
      metadata: {
        data_quality_score: 0.95,
        feature_completeness: 1.0
      }
    }
    // ... more records
  ],
  labels: {
    type: "continuous",
    target_variable: "engagement_rate",
    min_value: 0.0,
    max_value: 1.0
  },
  statistics: {
    record_count: 15000,
    feature_means: {
      follower_count: 2543.5,
      engagement_rate: 0.042
    },
    feature_stds: {
      follower_count: 1234.2,
      engagement_rate: 0.023
    },
    class_distribution: null  // for classification tasks
  },
  train_split: [0, 1, 2, /* ... */ 11999],  // 80% = 12000 records
  validation_split: [12000, 12001, /* ... */ 13499],  // 10% = 1500 records
  test_split: [13500, 13501, /* ... */ 14999],  // 10% = 1500 records
  created_at: new Date("2024-04-01T00:00:00Z"),
  created_by: NumberLong(1)
});

// ============================================================================
// AI PERSONA ANALYSIS (Deep Dive)
// ============================================================================

// Collection: ai_persona_analysis
// Purpose: Store detailed AI-generated persona profiles for segments
db.createCollection("ai_persona_analysis", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["segment_id", "persona_profile", "generated_at"],
      properties: {
        segment_id: {
          bsonType: "long",
          description: "Reference to PostgreSQL ai_segments.id"
        },
        persona_profile: {
          bsonType: "object",
          required: ["name", "description"],
          properties: {
            name: { bsonType: "string" },
            description: { bsonType: "string" },
            archetype: { bsonType: "string" },  // e.g., "Early Adopter", "Brand Advocate"
            avatar_url: { bsonType: "string" }
          }
        },
        demographics: {
          bsonType: "object",
          properties: {
            age_distribution: { bsonType: "object" },
            gender_distribution: { bsonType: "object" },
            location_distribution: { bsonType: "array" },
            language_distribution: { bsonType: "array" },
            education_level: { bsonType: "object" },
            income_level: { bsonType: "object" }
          }
        },
        psychographics: {
          bsonType: "object",
          properties: {
            values: { bsonType: "array" },
            personality_traits: { bsonType: "object" },
            lifestyle: { bsonType: "array" },
            attitudes: { bsonType: "object" }
          }
        },
        behavioral_patterns: {
          bsonType: "object",
          properties: {
            posting_habits: { bsonType: "object" },
            engagement_patterns: { bsonType: "object" },
            content_preferences: { bsonType: "array" },
            active_times: { bsonType: "array" },
            device_usage: { bsonType: "object" }
          }
        },
        interests: {
          bsonType: "array",
          items: {
            bsonType: "object",
            properties: {
              category: { bsonType: "string" },
              subcategories: { bsonType: "array" },
              affinity_score: { bsonType: "double" }
            }
          }
        },
        brand_affinities: {
          bsonType: "array",
          items: {
            bsonType: "object",
            properties: {
              brand_name: { bsonType: "string" },
              affinity_score: { bsonType: "double" },
              interaction_types: { bsonType: "array" }
            }
          }
        },
        content_recommendations: {
          bsonType: "object",
          properties: {
            themes: { bsonType: "array" },
            formats: { bsonType: "array" },
            tone: { bsonType: "string" },
            hashtags: { bsonType: "array" },
            best_posting_times: { bsonType: "array" }
          }
        },
        pain_points: {
          bsonType: "array",
          description: "Identified challenges or needs"
        },
        motivations: {
          bsonType: "array",
          description: "What drives this segment"
        },
        ai_model_used: {
          bsonType: "string",
          description: "Model that generated this analysis"
        },
        confidence_score: {
          bsonType: "double",
          minimum: 0,
          maximum: 1
        },
        generated_at: {
          bsonType: "date"
        }
      }
    }
  }
});

// Indexes
db.ai_persona_analysis.createIndex({ "segment_id": 1 }, { unique: true });
db.ai_persona_analysis.createIndex({ "persona_profile.archetype": 1 });
db.ai_persona_analysis.createIndex({ "interests.category": 1 });

// Text index for search
db.ai_persona_analysis.createIndex({
  "persona_profile.description": "text",
  "behavioral_patterns.content_preferences": "text",
  "interests.category": "text"
});

// Sample document
db.ai_persona_analysis.insertOne({
  segment_id: NumberLong(456),
  persona_profile: {
    name: "Tech-Savvy Millennials",
    description: "Early adopters aged 25-34 who are passionate about technology, follow tech influencers, and engage heavily with product launches and tech news.",
    archetype: "Early Adopter",
    avatar_url: "https://storage.example.com/personas/tech_millennial.png"
  },
  demographics: {
    age_distribution: {
      "18-24": 0.15,
      "25-34": 0.65,
      "35-44": 0.20
    },
    gender_distribution: {
      "male": 0.68,
      "female": 0.30,
      "other": 0.02
    },
    location_distribution: [
      { country: "US", percentage: 0.45, cities: ["San Francisco", "New York", "Seattle"] },
      { country: "UK", percentage: 0.15, cities: ["London", "Manchester"] },
      { country: "CA", percentage: 0.12, cities: ["Toronto", "Vancouver"] }
    ],
    language_distribution: [
      { language: "en", percentage: 0.85 },
      { language: "es", percentage: 0.10 }
    ],
    education_level: {
      "high_school": 0.10,
      "bachelors": 0.55,
      "masters": 0.30,
      "phd": 0.05
    }
  },
  psychographics: {
    values: ["innovation", "efficiency", "sustainability", "authenticity"],
    personality_traits: {
      "openness": 0.82,
      "conscientiousness": 0.65,
      "extraversion": 0.55,
      "agreeableness": 0.60,
      "neuroticism": 0.40
    },
    lifestyle: ["urban", "digital_nomad", "fitness_conscious", "environmentally_aware"],
    attitudes: {
      "brand_loyalty": "moderate",
      "price_sensitivity": "low",
      "social_influence": "high"
    }
  },
  behavioral_patterns: {
    posting_habits: {
      avg_posts_per_week: 4.2,
      preferred_formats: ["stories", "reels", "carousel"],
      peak_posting_times: ["9-11am", "6-9pm"]
    },
    engagement_patterns: {
      avg_engagement_rate: 0.048,
      preferred_engagement_type: ["likes", "saves", "shares"],
      comment_frequency: "moderate",
      share_propensity: "high"
    },
    content_preferences: [
      "product_reviews",
      "tech_tutorials",
      "industry_news",
      "behind_the_scenes",
      "infographics"
    ],
    active_times: [
      { day: "Monday", hours: [8, 9, 10, 18, 19, 20, 21] },
      { day: "Tuesday", hours: [8, 9, 18, 19, 20] }
      // ... other days
    ],
    device_usage: {
      "mobile": 0.75,
      "desktop": 0.20,
      "tablet": 0.05
    }
  },
  interests: [
    {
      category: "Technology",
      subcategories: ["AI/ML", "Mobile Tech", "SaaS", "Gadgets"],
      affinity_score: 0.92
    },
    {
      category: "Business",
      subcategories: ["Startups", "Entrepreneurship", "Productivity"],
      affinity_score: 0.78
    },
    {
      category: "Lifestyle",
      subcategories: ["Fitness", "Travel", "Food"],
      affinity_score: 0.65
    }
  ],
  brand_affinities: [
    {
      brand_name: "Apple",
      affinity_score: 0.88,
      interaction_types: ["follows", "likes", "comments", "shares"]
    },
    {
      brand_name: "Tesla",
      affinity_score: 0.82,
      interaction_types: ["follows", "likes", "saves"]
    }
  ],
  content_recommendations: {
    themes: [
      "Product innovation stories",
      "Industry thought leadership",
      "Tutorial and how-to content",
      "Tech event coverage"
    ],
    formats: ["short_video", "carousel", "infographic", "live_stream"],
    tone: "informative_yet_casual",
    hashtags: ["#TechNews", "#Innovation", "#Startup", "#AI", "#Productivity"],
    best_posting_times: [
      { day: "Tuesday", time: "9:00am" },
      { day: "Thursday", time: "2:00pm" },
      { day: "Sunday", time: "7:00pm" }
    ]
  },
  pain_points: [
    "Information overload from too many tech sources",
    "Difficulty finding authentic product reviews",
    "Limited time to stay updated on tech trends"
  ],
  motivations: [
    "Stay ahead of technology trends",
    "Optimize personal and professional productivity",
    "Connect with like-minded tech enthusiasts",
    "Discover innovative products before mainstream adoption"
  ],
  ai_model_used: "gpt-4-turbo-with-vision",
  confidence_score: 0.87,
  generated_at: new Date("2024-04-15T14:30:00Z")
});

// ============================================================================
// MODEL PREDICTION HISTORY (Large Scale)
// ============================================================================

// Collection: model_predictions_history
// Purpose: Store historical predictions for analysis and debugging
db.createCollection("model_predictions_history", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["model_id", "predictions", "predicted_at"],
      properties: {
        model_id: {
          bsonType: "long",
          description: "Reference to PostgreSQL ai_models.id"
        },
        model_version: {
          bsonType: "string"
        },
        batch_id: {
          bsonType: "string",
          description: "Batch inference ID"
        },
        predictions: {
          bsonType: "array",
          items: {
            bsonType: "object",
            properties: {
              follower_id: { bsonType: "long" },
              prediction: {},
              confidence: { bsonType: "double" },
              features_used: { bsonType: "object" }
            }
          }
        },
        inference_metadata: {
          bsonType: "object",
          properties: {
            total_predictions: { bsonType: "int" },
            avg_inference_time_ms: { bsonType: "double" },
            compute_resource: { bsonType: "string" }
          }
        },
        predicted_at: {
          bsonType: "date"
        }
      }
    }
  }
});

// Indexes
db.model_predictions_history.createIndex({ "model_id": 1, "predicted_at": -1 });
db.model_predictions_history.createIndex({ "batch_id": 1 });

// TTL: Auto-delete predictions older than 180 days
db.model_predictions_history.createIndex(
  { "predicted_at": 1 },
  { expireAfterSeconds: 15552000 }  // 180 days
);

// ============================================================================
// CONTENT GENERATION HISTORY
// ============================================================================

// Collection: ai_generated_content
// Purpose: Store AI-generated ad creative and copy history
db.createCollection("ai_generated_content", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["campaign_id", "content_type", "generated_content", "generated_at"],
      properties: {
        campaign_id: {
          bsonType: "long"
        },
        ad_creative_id: {
          bsonType: "long"
        },
        content_type: {
          enum: ["headline", "body_copy", "cta", "image_prompt", "video_script", "complete_ad"],
          description: "Type of content generated"
        },
        generated_content: {
          bsonType: "object",
          description: "The actual generated content"
        },
        prompt_used: {
          bsonType: "string",
          description: "Prompt sent to AI model"
        },
        model_used: {
          bsonType: "string",
          description: "AI model name (gpt-4, dall-e-3, etc.)"
        },
        generation_params: {
          bsonType: "object",
          description: "Parameters like temperature, max_tokens"
        },
        target_segment: {
          bsonType: "long",
          description: "Segment ID this content was tailored for"
        },
        performance_metrics: {
          bsonType: "object",
          description: "A/B test results if applicable"
        },
        human_edited: {
          bsonType: "bool",
          description: "Whether content was edited by human"
        },
        approved: {
          bsonType: "bool"
        },
        generated_at: {
          bsonType: "date"
        },
        cost_usd: {
          bsonType: "double",
          description: "API cost for generation"
        }
      }
    }
  }
});

// Indexes
db.ai_generated_content.createIndex({ "campaign_id": 1 });
db.ai_generated_content.createIndex({ "content_type": 1 });
db.ai_generated_content.createIndex({ "generated_at": -1 });
db.ai_generated_content.createIndex({ "approved": 1 });

// Sample document
db.ai_generated_content.insertOne({
  campaign_id: NumberLong(789),
  ad_creative_id: NumberLong(101112),
  content_type: "complete_ad",
  generated_content: {
    headline: "Unlock Your Productivity Potential",
    body_copy: "Join 50,000+ tech professionals who've transformed their workflow with our AI-powered tools. Start your free trial today.",
    cta: "Start Free Trial",
    image_description: "Modern workspace with laptop displaying analytics dashboard, natural lighting, minimalist aesthetic"
  },
  prompt_used: "Generate an Instagram ad for a productivity SaaS tool targeting tech-savvy millennials aged 25-34. Emphasize innovation and efficiency. Tone: informative yet casual.",
  model_used: "gpt-4-turbo",
  generation_params: {
    temperature: 0.7,
    max_tokens: 200,
    top_p: 0.9
  },
  target_segment: NumberLong(456),
  performance_metrics: {
    impressions: 15000,
    clicks: 720,
    ctr: 0.048,
    conversions: 36,
    conversion_rate: 0.05
  },
  human_edited: true,
  approved: true,
  generated_at: new Date("2024-04-20T10:15:00Z"),
  cost_usd: 0.02
});

// ============================================================================
// EXPERIMENT RESULTS (A/B Tests)
// ============================================================================

// Collection: ab_test_experiments
// Purpose: Store A/B test configurations and results
db.createCollection("ab_test_experiments", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["experiment_name", "campaign_id", "variants", "started_at"],
      properties: {
        experiment_name: { bsonType: "string" },
        campaign_id: { bsonType: "long" },
        hypothesis: { bsonType: "string" },
        variants: {
          bsonType: "array",
          items: {
            bsonType: "object",
            properties: {
              variant_name: { bsonType: "string" },
              ad_creative_id: { bsonType: "long" },
              traffic_allocation: { bsonType: "double" },
              metrics: { bsonType: "object" }
            }
          }
        },
        success_metric: { bsonType: "string" },
        minimum_sample_size: { bsonType: "int" },
        confidence_level: { bsonType: "double" },
        results: {
          bsonType: "object",
          properties: {
            winner: { bsonType: "string" },
            statistical_significance: { bsonType: "bool" },
            p_value: { bsonType: "double" },
            lift_percentage: { bsonType: "double" }
          }
        },
        status: { enum: ["running", "completed", "stopped"] },
        started_at: { bsonType: "date" },
        completed_at: { bsonType: "date" }
      }
    }
  }
});

// Indexes
db.ab_test_experiments.createIndex({ "campaign_id": 1 });
db.ab_test_experiments.createIndex({ "status": 1 });
db.ab_test_experiments.createIndex({ "started_at": -1 });

