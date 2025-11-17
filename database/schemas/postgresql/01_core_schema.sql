-- ============================================================================
-- PostgreSQL Core Schema for AI-Powered Follower Intelligence System
-- Version: 1.0
-- Description: Transactional database for users, campaigns, followers, and AI segments
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- For fuzzy text search
CREATE EXTENSION IF NOT EXISTS "btree_gin";  -- For multi-column GIN indexes
CREATE EXTENSION IF NOT EXISTS "postgis";  -- For geo-targeting

-- ============================================================================
-- ORGANIZATIONS & USERS
-- ============================================================================

CREATE TABLE organizations (
  id BIGSERIAL PRIMARY KEY,
  uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(100) UNIQUE NOT NULL,
  tier VARCHAR(50) NOT NULL DEFAULT 'free',
  status VARCHAR(50) NOT NULL DEFAULT 'active',
  
  max_social_accounts INT NOT NULL DEFAULT 1,
  max_followers_tracked INT NOT NULL DEFAULT 10000,
  max_campaigns_per_month INT NOT NULL DEFAULT 3,
  
  settings JSONB DEFAULT '{}',
  billing_email VARCHAR(255),
  stripe_customer_id VARCHAR(255),
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  
  CONSTRAINT tier_check CHECK (tier IN ('free', 'starter', 'professional', 'enterprise'))
);

CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
  organization_id BIGINT NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255),
  email_verified_at TIMESTAMPTZ,
  
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  avatar_url TEXT,
  timezone VARCHAR(50) DEFAULT 'UTC',
  
  role VARCHAR(50) NOT NULL DEFAULT 'member',
  permissions JSONB DEFAULT '[]',
  
  oauth_provider VARCHAR(50),
  oauth_provider_id VARCHAR(255),
  
  last_login_at TIMESTAMPTZ,
  last_login_ip INET,
  two_factor_enabled BOOLEAN DEFAULT FALSE,
  two_factor_secret VARCHAR(255),
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  
  CONSTRAINT role_check CHECK (role IN ('owner', 'admin', 'member', 'viewer'))
);

CREATE TABLE api_keys (
  id BIGSERIAL PRIMARY KEY,
  uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  organization_id BIGINT NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  
  name VARCHAR(255) NOT NULL,
  key_hash VARCHAR(255) NOT NULL UNIQUE,
  key_prefix VARCHAR(20) NOT NULL,
  
  scopes JSONB DEFAULT '["read"]',
  
  last_used_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  revoked_at TIMESTAMPTZ
);

CREATE TABLE social_accounts (
  id BIGSERIAL PRIMARY KEY,
  uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
  organization_id BIGINT NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  
  platform VARCHAR(50) NOT NULL,
  platform_user_id VARCHAR(255) NOT NULL,
  username VARCHAR(255) NOT NULL,
  display_name VARCHAR(255),
  
  access_token_encrypted BYTEA,
  refresh_token_encrypted BYTEA,
  token_expires_at TIMESTAMPTZ,
  encryption_key_id VARCHAR(100),
  
  follower_count INT DEFAULT 0,
  following_count INT DEFAULT 0,
  post_count INT DEFAULT 0,
  
  last_synced_at TIMESTAMPTZ,
  sync_status VARCHAR(50) DEFAULT 'pending',
  sync_error TEXT,
  
  profile_data JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  
  CONSTRAINT platform_check CHECK (platform IN ('instagram', 'twitter', 'linkedin', 'tiktok', 'youtube', 'facebook')),
  CONSTRAINT unique_platform_account UNIQUE (platform, platform_user_id)
);

CREATE TABLE followers (
  id BIGSERIAL PRIMARY KEY,
  uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
  social_account_id BIGINT NOT NULL REFERENCES social_accounts(id) ON DELETE CASCADE,
  
  platform VARCHAR(50) NOT NULL,
  platform_user_id VARCHAR(255) NOT NULL,
  username VARCHAR(255) NOT NULL,
  display_name VARCHAR(255),
  
  bio TEXT,
  profile_image_url TEXT,
  profile_url TEXT,
  verified BOOLEAN DEFAULT FALSE,
  
  follower_count INT,
  following_count INT,
  post_count INT,
  
  location_text VARCHAR(255),
  location_coordinates GEOGRAPHY(POINT),
  
  profile_data JSONB DEFAULT '{}',
  enriched_data JSONB DEFAULT '{}',
  enrichment_status VARCHAR(50) DEFAULT 'pending',
  enriched_at TIMESTAMPTZ,
  
  avg_engagement_rate FLOAT,
  last_post_at TIMESTAMPTZ,
  
  follow_status VARCHAR(50) DEFAULT 'active',
  followed_at TIMESTAMPTZ,
  unfollowed_at TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  CONSTRAINT unique_follower UNIQUE (social_account_id, platform, platform_user_id),
  CONSTRAINT follow_status_check CHECK (follow_status IN ('active', 'unfollowed', 'blocked'))
);

ALTER TABLE followers ADD COLUMN search_vector tsvector;

CREATE OR REPLACE FUNCTION update_follower_search_vector()
RETURNS TRIGGER AS $$
BEGIN
  NEW.search_vector := to_tsvector('english',
    COALESCE(NEW.username, '') || ' ' ||
    COALESCE(NEW.display_name, '') || ' ' ||
    COALESCE(NEW.bio, '')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER follower_search_vector_update
  BEFORE INSERT OR UPDATE ON followers
  FOR EACH ROW
  EXECUTE FUNCTION update_follower_search_vector();

CREATE TABLE ai_segments (
  id BIGSERIAL PRIMARY KEY,
  uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
  organization_id BIGINT NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  social_account_id BIGINT REFERENCES social_accounts(id) ON DELETE CASCADE,
  
  name VARCHAR(255) NOT NULL,
  description TEXT,
  
  segment_type VARCHAR(50) NOT NULL,
  ai_model_used VARCHAR(100),
  
  criteria JSONB NOT NULL DEFAULT '{}',
  
  member_count INT DEFAULT 0,
  avg_engagement_rate FLOAT,
  
  persona_name VARCHAR(255),
  persona_description TEXT,
  persona_attributes JSONB DEFAULT '{}',
  
  status VARCHAR(50) DEFAULT 'active',
  computed_at TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  CONSTRAINT segment_type_check CHECK (segment_type IN ('demographic', 'behavioral', 'interest', 'predictive', 'custom'))
);

CREATE TABLE segment_members (
  id BIGSERIAL PRIMARY KEY,
  segment_id BIGINT NOT NULL REFERENCES ai_segments(id) ON DELETE CASCADE,
  follower_id BIGINT NOT NULL REFERENCES followers(id) ON DELETE CASCADE,
  
  match_score FLOAT,
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  CONSTRAINT unique_segment_member UNIQUE (segment_id, follower_id)
);

CREATE TABLE campaigns (
  id BIGSERIAL PRIMARY KEY,
  uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
  organization_id BIGINT NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  
  name VARCHAR(255) NOT NULL,
  description TEXT,
  
  objective VARCHAR(100) NOT NULL,
  platforms VARCHAR(50)[] NOT NULL,
  
  target_segment_ids BIGINT[],
  geo_targeting JSONB DEFAULT '{}',
  demographic_targeting JSONB DEFAULT '{}',
  
  budget_total DECIMAL(12, 2),
  budget_daily DECIMAL(12, 2),
  currency VARCHAR(3) DEFAULT 'USD',
  bid_strategy VARCHAR(50),
  
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  schedule JSONB DEFAULT '{}',
  
  status VARCHAR(50) NOT NULL DEFAULT 'draft',
  
  impressions_total BIGINT DEFAULT 0,
  clicks_total BIGINT DEFAULT 0,
  conversions_total BIGINT DEFAULT 0,
  spend_total DECIMAL(12, 2) DEFAULT 0,
  
  created_by BIGINT REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  CONSTRAINT objective_check CHECK (objective IN ('awareness', 'engagement', 'conversions', 'traffic', 'app_installs')),
  CONSTRAINT status_check CHECK (status IN ('draft', 'scheduled', 'active', 'paused', 'completed', 'cancelled'))
);

CREATE TABLE ad_groups (
  id BIGSERIAL PRIMARY KEY,
  uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
  campaign_id BIGINT NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
  
  name VARCHAR(255) NOT NULL,
  target_segment_ids BIGINT[],
  targeting_override JSONB DEFAULT '{}',
  bid_amount DECIMAL(12, 2),
  status VARCHAR(50) NOT NULL DEFAULT 'active',
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE ad_creatives (
  id BIGSERIAL PRIMARY KEY,
  uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
  campaign_id BIGINT NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
  ad_group_id BIGINT REFERENCES ad_groups(id) ON DELETE CASCADE,
  
  name VARCHAR(255) NOT NULL,
  format VARCHAR(50) NOT NULL,
  headline VARCHAR(255),
  body TEXT,
  call_to_action VARCHAR(50),
  
  media_urls TEXT[],
  thumbnail_url TEXT,
  
  ai_generated BOOLEAN DEFAULT FALSE,
  ai_model_used VARCHAR(100),
  ai_prompt TEXT,
  generation_params JSONB DEFAULT '{}',
  
  platform_specs JSONB DEFAULT '{}',
  variant_group VARCHAR(100),
  
  status VARCHAR(50) NOT NULL DEFAULT 'draft',
  approval_status VARCHAR(50) DEFAULT 'pending',
  
  impressions_total BIGINT DEFAULT 0,
  clicks_total BIGINT DEFAULT 0,
  ctr FLOAT,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  CONSTRAINT format_check CHECK (format IN ('image', 'video', 'carousel', 'story', 'collection'))
);

CREATE TABLE ai_models (
  id BIGSERIAL PRIMARY KEY,
  uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
  
  name VARCHAR(255) NOT NULL,
  model_type VARCHAR(100) NOT NULL,
  framework VARCHAR(50),
  version VARCHAR(50) NOT NULL,
  
  model_artifact_url TEXT,
  model_size_bytes BIGINT,
  
  training_dataset_id BIGINT,
  training_params JSONB DEFAULT '{}',
  metrics JSONB DEFAULT '{}',
  
  status VARCHAR(50) DEFAULT 'training',
  
  created_by BIGINT REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deployed_at TIMESTAMPTZ,
  
  CONSTRAINT model_type_check CHECK (model_type IN ('segmentation', 'prediction', 'generation', 'classification', 'clustering'))
);

CREATE TABLE model_predictions (
  id BIGSERIAL PRIMARY KEY,
  model_id BIGINT NOT NULL REFERENCES ai_models(id) ON DELETE CASCADE,
  follower_id BIGINT NOT NULL REFERENCES followers(id) ON DELETE CASCADE,
  
  prediction_type VARCHAR(100) NOT NULL,
  prediction_value JSONB NOT NULL,
  confidence_score FLOAT,
  predicted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  CONSTRAINT unique_model_follower_prediction UNIQUE (model_id, follower_id, prediction_type)
);

CREATE TABLE audit_log (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(id),
  api_key_id BIGINT REFERENCES api_keys(id),
  ip_address INET,
  action VARCHAR(100) NOT NULL,
  resource_type VARCHAR(100) NOT NULL,
  resource_id BIGINT,
  changes JSONB,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  user_agent TEXT
);

-- Indexes
CREATE INDEX idx_users_org_id ON users(organization_id);
CREATE INDEX idx_social_accounts_org_id ON social_accounts(organization_id);
CREATE INDEX idx_followers_social_account ON followers(social_account_id);
CREATE INDEX idx_followers_platform_user ON followers(platform, platform_user_id);
CREATE INDEX idx_followers_profile_data ON followers USING GIN(profile_data);
CREATE INDEX idx_followers_enriched_data ON followers USING GIN(enriched_data);
CREATE INDEX idx_followers_search_vector ON followers USING GIN(search_vector);
CREATE INDEX idx_followers_location ON followers USING GIST(location_coordinates);
CREATE INDEX idx_segment_members_segment ON segment_members(segment_id);
CREATE INDEX idx_segment_members_follower ON segment_members(follower_id);
CREATE INDEX idx_campaigns_org_status ON campaigns(organization_id, status);
CREATE INDEX idx_ad_creatives_campaign ON ad_creatives(campaign_id);

-- RLS
ALTER TABLE social_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE followers ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_segments ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;

CREATE POLICY org_isolation_social_accounts ON social_accounts
  USING (organization_id = current_setting('app.current_org_id', true)::bigint);

CREATE POLICY org_isolation_followers ON followers
  USING (social_account_id IN (
    SELECT id FROM social_accounts 
    WHERE organization_id = current_setting('app.current_org_id', true)::bigint
  ));
