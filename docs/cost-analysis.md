# Cost Analysis & Optimization

All pricing in USD, us-east-1, based on November 2023 public rates.

## 1. Current Architecture Cost Breakdown (Dev Baseline)

| Component | Details | Monthly Estimate |
|-----------|---------|------------------|
| **Fargate Tasks** | 2 × 0.5 vCPU/1GB (product/order), 1 × 0.25 vCPU/0.5GB (frontend) @ $0.04048 per vCPU-hr + $0.004445 per GB-hr | ~$60 |
| **Application Load Balancer** | 730 hrs + 10 GB processed | ~$18 |
| **NAT Gateway** | 730 hrs + 50 GB data | ~$40 |
| **RDS db.t4g.micro** | 730 hrs + 20GB gp3 storage + backups | ~$33 |
| **CloudWatch Logs & Metrics** | 5 GB ingest + 3 custom alarms + dashboard | ~$8 |
| **ECR Storage & Scans** | 5 GB images + scan-on-push | ~$5 |
| **Data Transfer Out (1 TB)** | Via ALB to internet | ~$10 |
| **Total** | | **~$174 / month** |

## 2. Cost Optimization Strategies Implemented

1. **Fargate Spot Ready:** Terraform variables can toggle Spot capacity providers for stateless services, cutting compute costs up to 70%.
2. **Single Shared ALB:** Path-based routing avoids one-ALB-per-service pattern, saving ~$36+/month.
3. **Auto-Scaling Hooks:** ECS services configured with 50/200 healthy percent thresholds and CloudWatch metrics for future horizontal scaling. Scaling down to zero in dev hours saves compute.
4. **Lifecycle Policies:** ECR keeps only 10 latest images and purges untagged >7 days, reducing storage and scan charges.
5. **Automated Tear-down:** Runbook recommends nightly `terraform destroy` for sandboxes or scheduled `ecs update-service --desired-count 0`.

## 3. Scaling Cost Projections

| Scenario | Assumptions | Monthly Estimate |
|----------|-------------|------------------|
| **10× Traffic** | 3 tasks/service (9 total), RDS db.t3.medium, ALB 100 GB, NAT 200 GB | ~$520 |
| **100× Traffic** | 15 tasks/service (45 total), RDS db.m6g.large Multi-AZ, ALB 1 TB, NAT 2 TB, enable CloudFront | ~$4,800 |

**Recommendations:**
- At 10×, activate Fargate Spot + auto-scaling policies, enable Aurora Serverless v2 for DB elasticity.
- At 100×, introduce per-service ALBs or API Gateway, deploy read replicas, and add caching (ElastiCache/CloudFront) to offload origin.

## 4. FinOps Best Practices

- **Daily Cost Monitoring:** Automate `aws ce get-cost-and-usage` reports and pipe to Slack. Keep Cost Explorer filters by tag `Project=ecommerce`.
- **Budget Alerts:** Configure AWS Budgets for monthly spend + anomaly detection; route to same SNS topic as ops alarms.
- **Resource Tagging:** Enforce `Project`, `Environment`, `Owner`, `CostCenter` tags in Terraform to enable granular reporting.
- **Reserved Capacity Review:** For steady prod load, evaluate Compute Savings Plans (1-year partial) and RDS reserved instances for ~30% savings.

## 5. Cost vs. Performance Trade-offs

- **Multi-AZ RDS:** Doubles DB cost but improves HA. Enable for staging/prod once SLA requires <5 min failover.
- **NAT Gateway vs NAT Instance:** NAT GW is managed but ~$40/mo baseline. For tiny dev envs, consider NAT instance (t4g.nano) with autoscaling, accepting ops overhead.
- **CloudWatch Log Retention:** 7-day retention keeps observability affordable. For compliance, increase retention but apply metric filters to prevent excessive storage.
- **ALB vs API Gateway:** ALB cheaper for high-throughput HTTP; API Gateway adds features (WAF, caching) but costs ~$3.50 per million requests.

## Summary

Dev environment runs comfortably under $200/month. Production scale requires proactive auto-scaling, right-sizing of RDS, and leveraging savings plans. Continuous monitoring plus GitHub Actions automation keeps idle resources in check and ensures every component carries the mandated tags for accurate showback/chargeback.
