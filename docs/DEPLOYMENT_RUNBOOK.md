# Deployment Runbook

## Pre-Deployment Checklist

- [ ] Code reviewed and approved
- [ ] All tests passing (unit, integration, E2E)
- [ ] Security scan passed (no critical vulnerabilities)
- [ ] Database migrations tested
- [ ] Feature flags configured
- [ ] Monitoring dashboards updated
- [ ] Rollback plan documented
- [ ] Team notified (Slack #deployments)
- [ ] Change request approved (for production)

## Deployment Steps

### 1. Development Environment (Automatic)

```bash
# Triggered on push to develop branch
# No manual steps required
```

### 2. Staging Environment (Automatic on merge to main)

```bash
# 1. Verify staging deployment
kubectl get pods -n staging

# 2. Run smoke tests
./scripts/smoke-tests.sh --env=staging

# 3. Performance tests
k6 run tests/performance/load-test.js
```

### 3. Production Environment (Manual Approval Required)

```bash
# 1. Review changes
git log --oneline main...production

# 2. Create maintenance window (if needed)
# Notify users via status page

# 3. Approve deployment in GitHub Actions
# Click "Approve" in GitHub Actions workflow

# 4. Monitor canary deployment
kubectl get canary api-canary -n production --watch

# Canary progression:
# 0% → 5% (2 min) → 25% (5 min) → 50% (10 min) → 100%

# 5. Watch metrics during rollout
# - Error rate < 0.1%
# - P95 latency < 500ms
# - CPU < 70%
# - Memory < 80%

# 6. Verify deployment
kubectl get pods -n production -l app=api
curl -f https://app.followerintel.com/health
```

## Rollback Procedure

```bash
# Automatic rollback triggers:
# - Error rate > 1%
# - P95 latency > 2s
# - Health checks failing
# - Pod crash loops

# Manual rollback:
kubectl rollout undo deployment/api-service -n production

# Verify rollback
kubectl rollout status deployment/api-service -n production
```

## Post-Deployment Verification

- [ ] All pods running and healthy
- [ ] Health endpoints returning 200
- [ ] Error rate < 0.1%
- [ ] Latency within SLOs
- [ ] Database connections normal
- [ ] Cache hit ratio normal
- [ ] No alerts firing
- [ ] User-facing features working
- [ ] Update CHANGELOG.md
- [ ] Close deployment ticket

## Incident Response

If deployment causes incidents:

1. **Immediate**: Trigger rollback
2. **Notify**: Alert on-call engineer via PagerDuty
3. **Communicate**: Update status page
4. **Investigate**: Check logs, metrics, traces
5. **Fix**: Create hotfix branch
6. **Post-mortem**: Document lessons learned

## Contacts

- **On-Call Engineer**: Check PagerDuty schedule
- **DevOps Team**: #devops-team Slack channel
- **Security Team**: security@followerintel.com
- **PagerDuty**: https://followerintel.pagerduty.com

