# API Specification

## Overview
RESTful API specification for the AI-Powered Follower Intelligence Platform.

**Base URL**: `https://api.platform.com/v1`

**Authentication**: Bearer token (JWT) in Authorization header

---

## 1. Authentication Endpoints

### POST /auth/register
Register a new user account.

**Request**:
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "full_name": "John Doe",
  "username": "johndoe"
}
```

**Response** (201 Created):
```json
{
  "status": "success",
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "username": "johndoe",
      "full_name": "John Doe",
      "email_verified": false
    },
    "access_token": "jwt_token",
    "refresh_token": "refresh_token",
    "expires_in": 900
  }
}
```

### POST /auth/login
Authenticate user and receive tokens.

**Request**:
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!"
}
```

**Response** (200 OK):
```json
{
  "status": "success",
  "data": {
    "user": { "id": "uuid", "email": "...", ... },
    "access_token": "jwt_token",
    "refresh_token": "refresh_token",
    "expires_in": 900
  }
}
```

### POST /auth/refresh
Refresh access token using refresh token.

**Request**:
```json
{
  "refresh_token": "refresh_token"
}
```

**Response** (200 OK):
```json
{
  "status": "success",
  "data": {
    "access_token": "new_jwt_token",
    "expires_in": 900
  }
}
```

### POST /auth/logout
Invalidate current session.

**Response** (204 No Content)

---

## 2. Social Media Integration Endpoints

### GET /social-accounts
List all connected social media accounts.

**Query Parameters**:
- `platform` (optional): Filter by platform (instagram, twitter, etc.)
- `status` (optional): Filter by status (active, expired, revoked)

**Response** (200 OK):
```json
{
  "status": "success",
  "data": {
    "social_accounts": [
      {
        "id": "uuid",
        "platform": "instagram",
        "platform_username": "john_doe",
        "display_name": "John Doe",
        "profile_image_url": "https://...",
        "follower_count": 5420,
        "following_count": 830,
        "status": "active",
        "last_synced_at": "2025-11-17T10:00:00Z",
        "created_at": "2025-10-01T00:00:00Z"
      }
    ]
  }
}
```

### POST /social-accounts/connect
Initiate OAuth flow to connect a social media account.

**Request**:
```json
{
  "platform": "instagram",
  "redirect_uri": "https://yourapp.com/oauth/callback"
}
```

**Response** (200 OK):
```json
{
  "status": "success",
  "data": {
    "authorization_url": "https://instagram.com/oauth/authorize?...",
    "state": "random_state_token"
  }
}
```

### POST /social-accounts/callback
Handle OAuth callback and exchange code for tokens.

**Request**:
```json
{
  "platform": "instagram",
  "code": "oauth_code",
  "state": "state_token"
}
```

**Response** (201 Created):
```json
{
  "status": "success",
  "data": {
    "social_account": {
      "id": "uuid",
      "platform": "instagram",
      ...
    }
  }
}
```

### DELETE /social-accounts/{id}
Disconnect a social media account.

**Response** (204 No Content)

### POST /social-accounts/{id}/sync
Manually trigger follower data sync.

**Request** (optional):
```json
{
  "full_sync": true  // default: false (incremental)
}
```

**Response** (202 Accepted):
```json
{
  "status": "success",
  "data": {
    "job_id": "uuid",
    "status": "queued",
    "status_url": "/v1/jobs/uuid"
  }
}
```

---

## 3. Follower Endpoints

### GET /social-accounts/{id}/followers
Retrieve followers for a social account.

**Query Parameters**:
- `page` (default: 1)
- `per_page` (default: 50, max: 100)
- `sort_by` (options: engagement_rate, follower_count, username)
- `order` (options: asc, desc)
- `filter[interests]` (array): Filter by interests
- `filter[min_engagement]` (float): Minimum engagement rate
- `filter[location]` (string): Filter by location

**Response** (200 OK):
```json
{
  "status": "success",
  "data": {
    "followers": [
      {
        "id": "mongodb_id",
        "platform_follower_id": "123456",
        "username": "jane_smith",
        "display_name": "Jane Smith",
        "bio": "Travel blogger 🌍",
        "profile_image_url": "https://...",
        "follower_count": 2500,
        "engagement": {
          "avg_likes": 180,
          "avg_comments": 25,
          "engagement_rate": 0.082
        },
        "analysis": {
          "interests": [
            {"category": "travel", "confidence": 0.92},
            {"category": "photography", "confidence": 0.85}
          ],
          "demographics": {
            "age_range": "25-34",
            "gender": "female"
          }
        },
        "last_updated_at": "2025-11-17T00:00:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "per_page": 50,
      "total": 5420,
      "total_pages": 109
    }
  }
}
```

### GET /followers/{id}
Get detailed information about a specific follower.

**Response** (200 OK):
```json
{
  "status": "success",
  "data": {
    "follower": {
      "id": "mongodb_id",
      // ... full follower object with all analysis
    }
  }
}
```

### GET /followers/search
Semantic search for followers by interests, behavior, or description.

**Query Parameters**:
- `q` (required): Search query (e.g., "coffee lovers in LA")
- `social_account_id` (required)
- `limit` (default: 20, max: 100)

**Response** (200 OK):
```json
{
  "status": "success",
  "data": {
    "followers": [
      {
        "id": "...",
        "relevance_score": 0.95,
        ...
      }
    ]
  }
}
```

---

## 4. Segmentation Endpoints

### GET /segments
List all user segments.

**Query Parameters**:
- `social_account_id` (optional)
- `status` (optional): active, archived

**Response** (200 OK):
```json
{
  "status": "success",
  "data": {
    "segments": [
      {
        "id": "uuid",
        "name": "High-Engagement Coffee Lovers",
        "description": "Followers interested in coffee with >5% engagement",
        "follower_count": 245,
        "avg_engagement_rate": 0.078,
        "created_at": "2025-11-10T00:00:00Z",
        "last_generated_at": "2025-11-17T00:00:00Z"
      }
    ]
  }
}
```

### POST /segments
Create a new segment.

**Request**:
```json
{
  "social_account_id": "uuid",
  "name": "High-Engagement Coffee Lovers",
  "description": "...",
  "criteria": {
    "interests": ["coffee", "food_beverage"],
    "min_engagement_rate": 0.05,
    "min_follower_count": 500,
    "location": {
      "countries": ["US", "CA"]
    },
    "demographics": {
      "age_ranges": ["25-34", "35-44"]
    }
  }
}
```

**Response** (201 Created):
```json
{
  "status": "success",
  "data": {
    "segment": { ... },
    "job_id": "uuid" // for async generation
  }
}
```

### GET /segments/{id}
Get segment details including members.

**Query Parameters**:
- `include_members` (default: false): Include follower list
- `page`, `per_page` (if include_members=true)

**Response** (200 OK):
```json
{
  "status": "success",
  "data": {
    "segment": {
      "id": "uuid",
      "name": "...",
      "follower_count": 245,
      "criteria": { ... },
      "members": [ ... ] // if include_members=true
    }
  }
}
```

### PUT /segments/{id}
Update segment criteria and regenerate.

**Response** (200 OK + job_id for regeneration)

### DELETE /segments/{id}
Delete a segment.

**Response** (204 No Content)

### POST /segments/{id}/regenerate
Manually trigger segment regeneration.

**Response** (202 Accepted):
```json
{
  "status": "success",
  "data": {
    "job_id": "uuid"
  }
}
```

---

## 5. Persona Endpoints

### GET /segments/{id}/personas
Get personas for a segment.

**Response** (200 OK):
```json
{
  "status": "success",
  "data": {
    "personas": [
      {
        "id": "uuid",
        "segment_id": "uuid",
        "name": "Busy Coffee Professional",
        "description": "25-34 year old urban professional who values quality coffee...",
        "demographics": {
          "age_range": "25-34",
          "gender": "mixed",
          "location": "Urban US cities",
          "income_bracket": "middle-upper",
          "education": "bachelor_or_higher"
        },
        "psychographics": {
          "interests": ["specialty_coffee", "productivity", "wellness"],
          "values": ["quality", "efficiency", "sustainability"],
          "personality_traits": ["achievement-oriented", "health-conscious"],
          "lifestyle": "busy_professional"
        },
        "behaviors": {
          "social_media_usage": "daily, morning and evening",
          "preferred_platforms": ["instagram", "linkedin"],
          "content_preferences": ["educational", "aspirational"],
          "purchase_drivers": ["quality", "convenience", "brand_reputation"]
        },
        "goals": [
          "Find high-quality coffee for daily routine",
          "Discover productivity tips",
          "Maintain work-life balance"
        ],
        "pain_points": [
          "Limited time for coffee preparation",
          "Inconsistent quality from local shops",
          "High prices for premium coffee"
        ],
        "messaging_angles": [
          "Save time with premium coffee delivered",
          "Consistent quality, every morning",
          "Elevate your daily routine"
        ],
        "preferred_channels": ["instagram_stories", "sponsored_posts"],
        "best_posting_times": {
          "weekdays": ["7-9am", "6-8pm"],
          "weekends": ["9-11am"]
        },
        "avatar_url": "https://s3.../persona-avatar.png",
        "created_at": "2025-11-17T00:00:00Z"
      }
    ]
  }
}
```

### POST /segments/{id}/personas/generate
Trigger AI persona generation for a segment.

**Request** (optional):
```json
{
  "num_personas": 3, // default: auto-determine
  "focus_areas": ["demographics", "psychographics"] // optional emphasis
}
```

**Response** (202 Accepted):
```json
{
  "status": "success",
  "data": {
    "job_id": "uuid"
  }
}
```

### GET /personas/{id}
Get detailed persona information.

**Response** (200 OK)

---

## 6. Campaign Endpoints

### GET /campaigns
List all campaigns.

**Query Parameters**:
- `status` (optional): draft, scheduled, active, paused, completed
- `page`, `per_page`
- `sort_by` (options: created_at, start_date, performance)

**Response** (200 OK):
```json
{
  "status": "success",
  "data": {
    "campaigns": [
      {
        "id": "uuid",
        "name": "Fall Coffee Promotion",
        "status": "active",
        "objective": "conversions",
        "platforms": ["instagram", "facebook"],
        "budget_amount": 5000.00,
        "budget_currency": "USD",
        "start_date": "2025-11-01T00:00:00Z",
        "end_date": "2025-11-30T23:59:59Z",
        "performance": {
          "impressions": 125000,
          "clicks": 3250,
          "conversions": 156,
          "spend": 3420.50,
          "ctr": 0.026,
          "cpa": 21.93,
          "roas": 4.2
        },
        "created_at": "2025-10-25T00:00:00Z"
      }
    ],
    "pagination": { ... }
  }
}
```

### POST /campaigns
Create a new campaign.

**Request**:
```json
{
  "name": "Fall Coffee Promotion",
  "description": "Promote new seasonal blend",
  "objective": "conversions",
  "segment_id": "uuid",
  "persona_id": "uuid", // optional
  "platforms": ["instagram", "facebook"],
  "budget_amount": 5000.00,
  "budget_currency": "USD",
  "daily_budget": 166.67,
  "start_date": "2025-11-01T00:00:00Z",
  "end_date": "2025-11-30T23:59:59Z",
  "timezone": "America/New_York"
}
```

**Response** (201 Created):
```json
{
  "status": "success",
  "data": {
    "campaign": { ... }
  }
}
```

### GET /campaigns/{id}
Get campaign details.

**Query Parameters**:
- `include_ads` (default: false)
- `include_analytics` (default: false)

**Response** (200 OK)

### PUT /campaigns/{id}
Update campaign.

**Response** (200 OK)

### DELETE /campaigns/{id}
Delete campaign (soft delete if has spend).

**Response** (204 No Content)

### POST /campaigns/{id}/pause
Pause an active campaign.

**Response** (200 OK)

### POST /campaigns/{id}/resume
Resume a paused campaign.

**Response** (200 OK)

---

## 7. Ad Generation Endpoints

### GET /campaigns/{id}/ads
List ads for a campaign.

**Response** (200 OK):
```json
{
  "status": "success",
  "data": {
    "ads": [
      {
        "id": "uuid",
        "name": "Seasonal Blend - Variant A",
        "type": "image",
        "headline": "Fall in Love with Our New Seasonal Blend",
        "body_text": "Rich, smooth, with hints of cinnamon and nutmeg...",
        "cta_text": "Shop Now",
        "cta_url": "https://shop.example.com/fall-blend",
        "media_urls": ["https://s3.../ad-image.jpg"],
        "thumbnail_url": "https://s3.../thumbnail.jpg",
        "generated_by": "ai_generated",
        "model_used": "gpt-4 + dalle-3",
        "variant_group": "seasonal_blend_test",
        "variant_name": "A",
        "status": "approved",
        "performance": {
          "impressions": 45000,
          "clicks": 1200,
          "ctr": 0.0267
        },
        "created_at": "2025-10-28T00:00:00Z"
      }
    ]
  }
}
```

### POST /campaigns/{id}/ads/generate
Generate personalized ads using AI.

**Request**:
```json
{
  "num_variants": 3, // A/B/C testing
  "type": "image", // image, video, carousel
  "specifications": {
    "platform": "instagram", // for platform-specific sizing
    "format": "feed", // feed, story, reel
    "dimensions": {
      "width": 1080,
      "height": 1080
    }
  },
  "creative_brief": {
    "product_name": "Fall Seasonal Blend",
    "key_features": ["organic", "small-batch", "seasonal spices"],
    "tone": "warm, inviting, premium",
    "cta": "Shop Now",
    "landing_url": "https://shop.example.com/fall-blend"
  },
  "brand_guidelines": {
    "primary_colors": ["#8B4513", "#D2691E"],
    "fonts": ["Playfair Display", "Open Sans"],
    "logo_url": "https://s3.../logo.png",
    "brand_voice": "approachable yet sophisticated"
  },
  "personalization": {
    "use_persona": true, // use campaign persona
    "custom_messaging": null // or override
  }
}
```

**Response** (202 Accepted):
```json
{
  "status": "success",
  "data": {
    "job_id": "uuid",
    "estimated_completion_time": 30, // seconds
    "status_url": "/v1/jobs/uuid"
  }
}
```

### GET /ads/{id}
Get ad details.

**Response** (200 OK)

### PUT /ads/{id}
Update ad (manual edits).

**Response** (200 OK)

### POST /ads/{id}/approve
Approve ad for publishing.

**Response** (200 OK)

### POST /ads/{id}/reject
Reject ad with feedback.

**Request**:
```json
{
  "reason": "Off-brand messaging",
  "notes": "Please emphasize sustainability more"
}
```

**Response** (200 OK)

### DELETE /ads/{id}
Delete ad.

**Response** (204 No Content)

---

## 8. Analytics Endpoints

### GET /campaigns/{id}/analytics
Get campaign analytics.

**Query Parameters**:
- `start_date` (ISO 8601)
- `end_date` (ISO 8601)
- `granularity` (options: hour, day, week, month)
- `metrics` (array): impressions, clicks, conversions, spend, ctr, cpc, cpa, roas
- `group_by` (optional): platform, device_type, age_range, gender, country

**Response** (200 OK):
```json
{
  "status": "success",
  "data": {
    "analytics": {
      "summary": {
        "impressions": 125000,
        "clicks": 3250,
        "conversions": 156,
        "spend": 3420.50,
        "ctr": 0.026,
        "cpc": 1.05,
        "cpa": 21.93,
        "roas": 4.2
      },
      "time_series": [
        {
          "timestamp": "2025-11-01T00:00:00Z",
          "impressions": 5200,
          "clicks": 135,
          "conversions": 6,
          "spend": 142.10
        },
        // ... more data points
      ],
      "breakdown": {
        "by_platform": [
          {
            "platform": "instagram",
            "impressions": 75000,
            "clicks": 2100,
            "conversions": 98
          },
          {
            "platform": "facebook",
            "impressions": 50000,
            "clicks": 1150,
            "conversions": 58
          }
        ],
        "by_device": [ ... ],
        "by_demographics": [ ... ]
      }
    }
  }
}
```

### GET /ads/{id}/analytics
Get ad-specific analytics (same structure as campaign analytics).

**Response** (200 OK)

### GET /analytics/dashboard
Get user dashboard summary.

**Query Parameters**:
- `period` (options: today, week, month, quarter, year, custom)
- `start_date`, `end_date` (if period=custom)

**Response** (200 OK):
```json
{
  "status": "success",
  "data": {
    "summary": {
      "total_campaigns": 12,
      "active_campaigns": 3,
      "total_ads_generated": 156,
      "total_spend": 45230.50,
      "total_conversions": 2340,
      "avg_roas": 3.8
    },
    "top_campaigns": [ ... ],
    "top_ads": [ ... ],
    "trends": {
      "impressions_trend": 0.15, // +15%
      "ctr_trend": -0.03 // -3%
    }
  }
}
```

---

## 9. User Management Endpoints

### GET /users/me
Get current user profile.

**Response** (200 OK):
```json
{
  "status": "success",
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "username": "johndoe",
      "full_name": "John Doe",
      "email_verified": true,
      "subscription_tier": "pro",
      "preferences": { ... },
      "created_at": "2025-10-01T00:00:00Z"
    }
  }
}
```

### PUT /users/me
Update user profile.

**Request**:
```json
{
  "full_name": "John A. Doe",
  "username": "john_doe",
  "preferences": {
    "language": "en",
    "timezone": "America/New_York",
    "theme": "dark"
  }
}
```

**Response** (200 OK)

### POST /users/me/change-password
Change password.

**Request**:
```json
{
  "current_password": "OldPass123!",
  "new_password": "NewPass456!"
}
```

**Response** (200 OK)

### POST /users/me/data-export
Request GDPR data export.

**Response** (202 Accepted):
```json
{
  "status": "success",
  "data": {
    "export_id": "uuid",
    "status": "queued",
    "estimated_completion": "2025-11-17T12:00:00Z"
  }
}
```

### DELETE /users/me
Request account deletion (GDPR).

**Request**:
```json
{
  "password": "password",
  "confirmation": "DELETE MY ACCOUNT"
}
```

**Response** (202 Accepted):
```json
{
  "status": "success",
  "data": {
    "message": "Account deletion scheduled. Data will be deleted within 30 days.",
    "deletion_date": "2025-12-17T00:00:00Z"
  }
}
```

---

## 10. Billing Endpoints

### GET /subscriptions/current
Get current subscription details.

**Response** (200 OK):
```json
{
  "status": "success",
  "data": {
    "subscription": {
      "id": "uuid",
      "plan_id": "pro_monthly",
      "status": "active",
      "amount": 99.00,
      "currency": "USD",
      "billing_interval": "monthly",
      "current_period_start": "2025-11-01T00:00:00Z",
      "current_period_end": "2025-12-01T00:00:00Z",
      "usage": {
        "follower_syncs": 15,
        "follower_syncs_limit": 100,
        "ad_generations": 45,
        "ad_generations_limit": 500,
        "campaigns": 3,
        "campaigns_limit": 10
      }
    }
  }
}
```

### POST /subscriptions/upgrade
Upgrade subscription plan.

**Request**:
```json
{
  "plan_id": "pro_annual",
  "payment_method_id": "stripe_pm_id" // if needed
}
```

**Response** (200 OK)

### POST /subscriptions/cancel
Cancel subscription.

**Request** (optional):
```json
{
  "cancel_at_period_end": true, // default: false (immediate)
  "feedback": "Too expensive"
}
```

**Response** (200 OK)

### GET /invoices
List invoices.

**Query Parameters**:
- `page`, `per_page`

**Response** (200 OK):
```json
{
  "status": "success",
  "data": {
    "invoices": [
      {
        "id": "uuid",
        "amount": 99.00,
        "tax": 8.91,
        "total": 107.91,
        "currency": "USD",
        "status": "paid",
        "invoice_date": "2025-11-01",
        "paid_at": "2025-11-01T00:05:23Z",
        "invoice_pdf_url": "https://s3.../invoice.pdf"
      }
    ],
    "pagination": { ... }
  }
}
```

---

## 11. Job Status Endpoints

### GET /jobs/{id}
Get job status and results.

**Response** (200 OK):
```json
{
  "status": "success",
  "data": {
    "job": {
      "id": "uuid",
      "type": "follower_sync",
      "status": "completed", // queued, processing, completed, failed
      "progress": 100,
      "created_at": "2025-11-17T10:00:00Z",
      "started_at": "2025-11-17T10:00:15Z",
      "completed_at": "2025-11-17T10:03:42Z",
      "duration_seconds": 207,
      "result": {
        "followers_synced": 5420,
        "new_followers": 45,
        "updated_followers": 5375
      },
      "error": null
    }
  }
}
```

**If failed**:
```json
{
  "status": "success",
  "data": {
    "job": {
      "id": "uuid",
      "status": "failed",
      "error": {
        "code": "RATE_LIMIT_EXCEEDED",
        "message": "Instagram API rate limit exceeded. Retry in 1 hour.",
        "retry_after": "2025-11-17T11:00:00Z"
      }
    }
  }
}
```

---

## 12. WebSocket Endpoints

### WS /realtime
Real-time updates via WebSocket.

**Connection**:
```javascript
const ws = new WebSocket('wss://api.platform.com/v1/realtime?token=jwt_token');
```

**Subscribe to channels**:
```json
{
  "action": "subscribe",
  "channels": [
    "jobs.uuid",
    "campaigns.uuid.analytics",
    "user.notifications"
  ]
}
```

**Receive updates**:
```json
{
  "channel": "jobs.uuid",
  "event": "status_update",
  "data": {
    "job_id": "uuid",
    "status": "processing",
    "progress": 45
  },
  "timestamp": "2025-11-17T10:01:30Z"
}
```

---

## 13. Rate Limits

### Per-tier Limits

**Free Tier**:
- 100 requests/hour
- 1,000 requests/day

**Pro Tier**:
- 1,000 requests/hour
- 50,000 requests/day

**Enterprise**:
- Custom limits

### Rate Limit Headers

Every response includes:
```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 847
X-RateLimit-Reset: 1700233200
```

### Rate Limit Exceeded (429 Too Many Requests)

```json
{
  "status": "error",
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Rate limit exceeded. Retry after 2025-11-17T11:00:00Z",
    "retry_after": 3600
  }
}
```

---

## 14. Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| INVALID_INPUT | 400 | Request validation failed |
| UNAUTHORIZED | 401 | Missing or invalid authentication |
| FORBIDDEN | 403 | Insufficient permissions |
| NOT_FOUND | 404 | Resource not found |
| CONFLICT | 409 | Resource already exists |
| RATE_LIMIT_EXCEEDED | 429 | Too many requests |
| INTERNAL_ERROR | 500 | Server error |
| SERVICE_UNAVAILABLE | 503 | Temporary outage |
| SOCIAL_API_ERROR | 502 | External API error |
| INSUFFICIENT_QUOTA | 402 | Usage limit exceeded for plan |

---

## 15. Pagination

All list endpoints support cursor-based pagination:

**Request**:
```
GET /campaigns?page=2&per_page=50
```

**Response**:
```json
{
  "data": { ... },
  "pagination": {
    "page": 2,
    "per_page": 50,
    "total": 234,
    "total_pages": 5,
    "has_next": true,
    "has_prev": true,
    "next_url": "/v1/campaigns?page=3&per_page=50",
    "prev_url": "/v1/campaigns?page=1&per_page=50"
  }
}
```

---

## Summary

This API provides comprehensive functionality for:
- Social media integration and follower analysis
- AI-powered segmentation and persona generation
- Automated ad generation and campaign management
- Real-time analytics and performance tracking
- User and billing management
- GDPR compliance (data export, deletion)

All endpoints follow RESTful conventions, use standard HTTP methods and status codes, and provide consistent response formats.

