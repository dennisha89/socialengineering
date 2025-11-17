# Database Migrations

This directory contains database migration scripts for managing schema changes over time.

## Migration Tools

### PostgreSQL: Alembic (Python)

```bash
# Initialize Alembic
alembic init alembic

# Create a new migration
alembic revision -m "Add email_verified column to users"

# Run migrations
alembic upgrade head

# Rollback one version
alembic downgrade -1

# View migration history
alembic history
```

### Sample Migration (Alembic)

```python
# migrations/versions/001_add_email_verified.py

"""Add email_verified column to users

Revision ID: 001
Revises: 
Create Date: 2024-01-15 10:00:00

"""
from alembic import op
import sqlalchemy as sa

revision = '001'
down_revision = None
branch_labels = None
depends_on = None

def upgrade():
    # Add column with default
    op.add_column(
        'users',
        sa.Column('email_verified', sa.Boolean(), 
                 nullable=False, server_default='false')
    )
    
    # Create index
    op.create_index(
        'idx_users_email_verified',
        'users',
        ['email_verified']
    )

def downgrade():
    op.drop_index('idx_users_email_verified', table_name='users')
    op.drop_column('users', 'email_verified')
```

## Zero-Downtime Migration Strategy

### Adding a Column

**Phase 1:** Add column (nullable or with default)
```sql
ALTER TABLE followers ADD COLUMN sentiment_score FLOAT DEFAULT NULL;
```

**Phase 2:** Backfill data (in batches)
```python
# Backfill in batches to avoid long locks
for offset in range(0, total_rows, 1000):
    db.execute("""
        UPDATE followers 
        SET sentiment_score = calculate_sentiment(bio)
        WHERE id > :offset AND id <= :offset + 1000
    """, offset=offset)
```

**Phase 3:** Add NOT NULL constraint (after backfill)
```sql
ALTER TABLE followers ALTER COLUMN sentiment_score SET NOT NULL;
```

### Renaming a Column

**Phase 1:** Add new column
```sql
ALTER TABLE campaigns ADD COLUMN budget_total_cents BIGINT;
```

**Phase 2:** Dual-write (application writes to both)
```python
# Application code writes to both old and new
campaign.budget_amount = value
campaign.budget_total_cents = value * 100
```

**Phase 3:** Backfill old data
```sql
UPDATE campaigns SET budget_total_cents = budget_amount * 100
WHERE budget_total_cents IS NULL;
```

**Phase 4:** Switch reads to new column
```python
# Application now reads from new column
total_cents = campaign.budget_total_cents
```

**Phase 5:** Drop old column
```sql
ALTER TABLE campaigns DROP COLUMN budget_amount;
```

### Changing a Column Type

**Use intermediary column approach** (same as renaming)

Never use:
```sql
-- BAD: Locks table, rewrites data
ALTER TABLE followers ALTER COLUMN follower_count TYPE BIGINT;
```

Instead:
```sql
-- GOOD: Add new column, backfill, swap
ALTER TABLE followers ADD COLUMN follower_count_bigint BIGINT;
UPDATE followers SET follower_count_bigint = follower_count::BIGINT;
-- Then rename/swap in app
```

## Best Practices

1. **Always reversible**: Write `downgrade()` functions
2. **Test on staging**: Run migrations on copy of production data
3. **Batch operations**: Break large updates into smaller chunks
4. **Monitor locks**: Check for blocking queries during migration
5. **Avoid DDL in transactions**: Some operations can't be rolled back
6. **Version control**: Commit migrations with code changes
7. **Document breaking changes**: Note in migration comments

## TimescaleDB Migrations

```sql
-- Adding a column to hypertable
ALTER TABLE follower_engagement ADD COLUMN device_type VARCHAR(50);

-- Adding index to hypertable
CREATE INDEX CONCURRENTLY idx_follower_engagement_device 
  ON follower_engagement(device_type, time DESC);

-- Modifying retention policy
SELECT remove_retention_policy('follower_engagement');
SELECT add_retention_policy('follower_engagement', INTERVAL '180 days');
```

## MongoDB Migrations

MongoDB is schema-less, but you may need to migrate data formats:

```javascript
// Add field to all documents
db.followers.updateMany(
  { sentiment_score: { $exists: false } },
  { $set: { sentiment_score: null } }
);

// Rename field
db.followers.updateMany(
  {},
  { $rename: { "old_field": "new_field" } }
);

// Change data type
db.followers.find({ follower_count: { $type: "string" } }).forEach(doc => {
  db.followers.updateOne(
    { _id: doc._id },
    { $set: { follower_count: parseInt(doc.follower_count) } }
  );
});
```

## Emergency Rollback

If a migration causes issues in production:

```bash
# Immediate rollback
alembic downgrade -1

# Or restore from backup
# 1. Stop application
# 2. Restore database from latest backup
# 3. Deploy previous application version
# 4. Restart application
```

## Migration Checklist

Before running in production:

- [ ] Tested on staging with production-like data volume
- [ ] Estimated migration duration (should be < 5 minutes)
- [ ] Verified no long-running locks
- [ ] Prepared rollback plan
- [ ] Notified team of maintenance window
- [ ] Database backup completed
- [ ] Monitoring alerts configured
- [ ] Downgrade function tested

