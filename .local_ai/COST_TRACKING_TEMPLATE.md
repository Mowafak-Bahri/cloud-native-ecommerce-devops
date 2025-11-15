# 💰 AWS Cost Tracking Template

Use this document to track your daily AWS costs and stay within budget.

---

## 🎯 BUDGET TARGETS

| Budget Level | Amount | Action Required |
|-------------|--------|-----------------|
| **Green Zone** | $0 - $25 | Continue as planned |
| **Yellow Zone** | $25 - $35 | Review costs, identify spikes |
| **Orange Zone** | $35 - $50 | Stop non-essential testing, investigate |
| **Red Zone** | $50+ | STOP EVERYTHING, tear down resources |

---

## 📊 DAILY COST LOG

### Week 1: Foundation & Local Development

| Date | Daily Cost | MTD Total | Services Used | Notes | Action Taken |
|------|-----------|-----------|---------------|-------|--------------|
| Day 1 | $0.00 | $0.00 | None | Account setup, local dev only | ✅ All local |
| Day 2 | $0.00 | $0.00 | None | Docker testing locally | ✅ All local |
| Day 3 | $0.00 | $0.00 | None | Terraform learning | ✅ All local |
| Day 4 | $0.00 | $0.00 | None | Code development | ✅ All local |
| Day 5 | $0.00 | $0.00 | None | Documentation | ✅ All local |
| Day 6 | $0.00 | $0.00 | None | Planning Week 2 | ✅ All local |
| Day 7 | $0.00 | $0.00 | None | Rest day | ✅ All local |

### Week 2: Deploy to AWS

| Date | Daily Cost | MTD Total | Services Used | Notes | Action Taken |
|------|-----------|-----------|---------------|-------|--------------|
| Day 8 | $0.15 | $0.15 | VPC, Subnets, IGW | Deployed networking | ✅ Free tier |
| Day 9 | $0.50 | $0.65 | + ECR | Pushed first images | ✅ Within budget |
| Day 10 | $2.00 | $2.65 | + RDS t4g.micro | Database deployed | ✅ Free tier RDS |
| Day 11 | $1.80 | $4.45 | + ECS Cluster | Cluster created (no tasks yet) | ✅ No tasks = no Fargate cost |
| Day 12 | $18.50 | $22.95 | + ALB | ALB deployed (main cost driver) | ⚠️ Entered Yellow Zone |
| Day 13 | $2.50 | $25.45 | + Fargate tasks (3 services) | All services running | ⚠️ Monitor closely |
| Day 14 | $3.00 | $28.45 | All services | Testing deployment | ⚠️ Near budget threshold |

### Week 3: CI/CD, Monitoring & Security

| Date | Daily Cost | MTD Total | Services Used | Notes | Action Taken |
|------|-----------|-----------|---------------|-------|--------------|
| Day 15 | $2.80 | $31.25 | + CloudWatch Logs | Added monitoring | ⚠️ Implemented tear-down at night |
| Day 16 | $2.50 | $33.75 | + X-Ray | Distributed tracing added | ⚠️ Stopped tasks after testing |
| Day 17 | $2.20 | $35.95 | All services | CI/CD testing | 🚨 Orange Zone - stopped tasks 6PM-8AM |
| Day 18 | $1.50 | $37.45 | Reduced uptime | Testing only during work hours | ✅ Cost reduction working |
| Day 19 | $1.80 | $39.25 | + VPC Flow Logs (S3) | Security hardening | ✅ Used S3 not CloudWatch |
| Day 20 | $1.60 | $40.85 | All services | Testing security | ✅ Still in control |
| Day 21 | $0.80 | $41.65 | Minimal testing | Light usage day | ✅ Good progress |

### Week 4: Optimization & Portfolio

| Date | Daily Cost | MTD Total | Services Used | Notes | Action Taken |
|------|-----------|-----------|---------------|-------|--------------|
| Day 22 | $2.50 | $44.15 | Testing auto-scaling | Implemented Fargate Spot | ✅ 70% cost reduction on Spot |
| Day 23 | $1.20 | $45.35 | Spot tasks only | Cost optimization working! | ✅ Great savings |
| Day 24 | $0.90 | $46.25 | Documentation day | Minimal AWS usage | ✅ Focus on docs |
| Day 25 | $1.50 | $47.75 | Demo recording | Running services for video | ✅ Planned expense |
| Day 26 | $0.50 | $48.25 | Portfolio prep | Minimal testing | ✅ Almost done! |
| Day 27 | $0.40 | $48.65 | Final tests | Last checks before teardown | ✅ Ready to present |
| Day 28 | $0.00 | $48.65 | **TEARDOWN** | Destroyed all infrastructure | ✅ PROJECT COMPLETE! |

---

## 📈 COST BREAKDOWN BY SERVICE

Track which services are costing you money:

| Service | Week 1 | Week 2 | Week 3 | Week 4 | Total | Notes |
|---------|--------|--------|--------|--------|-------|-------|
| **Application Load Balancer** | $0 | $18.00 | $12.00 | $8.00 | $38.00 | Biggest cost (expected) |
| **ECS Fargate (On-Demand)** | $0 | $5.00 | $8.00 | $2.00 | $15.00 | Reduced in Week 4 with Spot |
| **ECS Fargate (Spot)** | $0 | $0 | $0 | $1.50 | $1.50 | 70% cheaper! |
| **RDS t4g.micro** | $0 | $2.00 | $2.00 | $2.00 | $6.00 | Free tier (750 hours/month) |
| **ECR Storage** | $0 | $0.50 | $0.50 | $0.50 | $1.50 | 500MB free tier |
| **CloudWatch Logs** | $0 | $0 | $1.00 | $0.50 | $1.50 | 5GB free tier |
| **CloudWatch Metrics** | $0 | $0 | $0.50 | $0.20 | $0.70 | 10 custom metrics free |
| **X-Ray** | $0 | $0 | $0.80 | $0.20 | $1.00 | 100K traces/month free |
| **VPC (NAT, Flow Logs)** | $0 | $0.50 | $0.50 | $0.50 | $1.50 | VPC free, Flow Logs to S3 |
| **S3 (Logs, Assets)** | $0 | $0.10 | $0.10 | $0.10 | $0.30 | 5GB free tier |
| **Secrets Manager** | $0 | $0.40 | $0.40 | $0.40 | $1.20 | $0.40/secret/month |
| **Data Transfer** | $0 | $0.50 | $1.00 | $0.50 | $2.00 | Minimal (testing only) |
| **Other** | $0 | $0.45 | $0.65 | $0.45 | $1.55 | Misc charges |
| **TOTAL** | **$0** | **$27.45** | **$27.45** | **$16.85** | **$71.75** | **Over budget by $21** |

**COST ANALYSIS:**
- ✅ **ALB:** Necessary for portfolio (shows real architecture)
- ✅ **Fargate:** Reduced cost 85% with Spot + limited hours
- ✅ **RDS:** Free tier covered
- ❌ **Overage:** Need to implement automated tear-down earlier

**LESSONS LEARNED:**
1. ALB costs $18-20/month no matter what (can't avoid)
2. Fargate Spot saves 70% - use it!
3. Running 24/7 = 3x cost vs 8 hours/day
4. CloudWatch logs grow fast - set retention to 7 days
5. Test locally first before AWS deployment

---

## 🎯 COST OPTIMIZATION CHECKLIST

### Before Week 2 (Before Deploying)
- [ ] Set up billing alerts ($25, $35, $50)
- [ ] Enable Cost Explorer
- [ ] Create budget in AWS Budgets
- [ ] Subscribe to daily cost emails
- [ ] Review free tier usage limits

### During Week 2 (Infrastructure Deployment)
- [ ] Use t4g instances (ARM - cheaper)
- [ ] Deploy RDS in single-AZ (dev environment)
- [ ] Use one ALB with path-based routing (not 3 ALBs)
- [ ] Enable ECR image scanning (security + free)
- [ ] Set CloudWatch Logs retention to 7 days
- [ ] Use S3 for VPC Flow Logs (not CloudWatch)

### During Week 3 (Running Services)
- [ ] Implement automated tear-down (Lambda + EventBridge)
- [ ] Use Fargate Spot for dev/staging
- [ ] Right-size Fargate tasks (0.25 vCPU, 0.5GB for testing)
- [ ] Stop tasks when not actively testing
- [ ] Monitor Cost Explorer daily
- [ ] Delete old ECR images

### During Week 4 (Optimization)
- [ ] Implement auto-scaling (scale to 0 when idle)
- [ ] Review Cost Explorer for anomalies
- [ ] Test Fargate Spot interruption handling
- [ ] Document all cost decisions
- [ ] Create tear-down runbook
- [ ] Schedule final infrastructure destruction

### After Project (Cleanup)
- [ ] Run `terraform destroy`
- [ ] Verify all resources deleted in AWS Console
- [ ] Check for lingering costs (snapshots, volumes, IPs)
- [ ] Delete S3 buckets
- [ ] Delete CloudWatch Log Groups
- [ ] Wait 24 hours and check Cost Explorer (ensure $0/day)

---

## 🚨 COST ALERTS & ACTIONS

### What to Do at Each Budget Level

**Green Zone ($0 - $25):**
- ✅ Continue as planned
- ✅ Deploy new services
- ✅ Test freely
- Action: Monitor daily, no changes needed

**Yellow Zone ($25 - $35):**
- ⚠️ Review Cost Explorer
- ⚠️ Identify top 3 cost drivers
- ⚠️ Stop non-essential testing
- Action: Implement tear-down schedule (stop tasks at night)

**Orange Zone ($35 - $50):**
- 🚨 Stop all active tasks immediately
- 🚨 Keep only infrastructure (VPC, ALB, RDS)
- 🚨 Switch to Fargate Spot
- Action: Only run tasks during active testing (2-4 hours/day)

**Red Zone ($50+):**
- 🛑 EMERGENCY - Run `terraform destroy`
- 🛑 Investigate cost spike in Cost Explorer
- 🛑 Contact AWS support if charges look wrong
- Action: Rebuild from code when ready (you have IaC!)

---

## 💡 FINOPS BEST PRACTICES

### Daily Habits
1. **Morning:** Check Cost Explorer (5 minutes)
2. **Before Deploying:** Ask "What will this cost?"
3. **After Testing:** Stop/delete resources
4. **Evening:** Review CloudWatch metrics for waste
5. **Weekly:** Calculate projected month-end cost

### Cost-Saving Techniques
| Technique | Savings | Complexity | When to Use |
|-----------|---------|------------|-------------|
| **Fargate Spot** | 70% | Low | Dev/staging always, prod mixed |
| **Scheduled Tear-Down** | 70% | Medium | Non-prod environments |
| **Right-Sizing** | 30-50% | Low | After load testing |
| **Single ALB** | $30-60/month | Medium | Always (path-based routing) |
| **S3 for Logs** | 50% | Low | Always (vs CloudWatch) |
| **Reserved Instances** | 40-60% | High | Only if running 24/7 for 1+ year |
| **Savings Plans** | 40-60% | High | Only for long-term projects |

### Questions to Ask Before Each Deployment
1. **What is the monthly cost of this resource?**
2. **Is there a cheaper alternative?**
3. **Can I use free tier?**
4. **Do I need this running 24/7?**
5. **Can I use Spot/Preemptible instances?**
6. **What's the cost at 10x scale?**

---

## 📞 WHEN TO ASK YOUR SUPERVISOR (ME)

**Ask me if:**
- Daily cost > $5 (something might be wrong)
- Total cost > $35 (need optimization help)
- Unexpected charges appear
- You don't understand a line item
- You want to deploy something expensive (e.g., NAT Gateway, ElastiCache)

**Before asking, provide:**
1. Screenshot of Cost Explorer
2. List of running resources (`aws resourcegroupstaggingapi get-resources`)
3. What you've already tried to reduce costs

---

## 🎯 TARGET: STAY UNDER $50 FOR ENTIRE PROJECT

**If you follow this plan:**
- Week 1: $0 (local dev)
- Week 2: $25-30 (infrastructure deployment)
- Week 3: $15-20 (with tear-down schedule)
- Week 4: $5-10 (mostly docs, spot instances)
- **Total: $45-60** (within acceptable range)

**Interview Talking Point:**
"I built a production-grade AWS infrastructure and kept costs under $50 for the entire month by implementing FinOps best practices: Fargate Spot for non-prod, automated tear-down schedules, right-sized resources, and proactive cost monitoring. In a real company, this same architecture would cost $500-1500/month, but I demonstrated I can architect efficiently."

---

## 📝 COST TRACKING COMMANDS

```bash
# Get today's cost
aws ce get-cost-and-usage \
  --time-period Start=$(date -u -d '1 day ago' +%Y-%m-%d),End=$(date -u +%Y-%m-%d) \
  --granularity DAILY \
  --metrics BlendedCost

# Get month-to-date
aws ce get-cost-and-usage \
  --time-period Start=$(date -u -d '1 day ago' +%Y-%m-01),End=$(date -u +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost

# Get cost by service
aws ce get-cost-and-usage \
  --time-period Start=$(date -u -d '7 days ago' +%Y-%m-%d),End=$(date -u +%Y-%m-%d) \
  --granularity DAILY \
  --metrics BlendedCost \
  --group-by Type=SERVICE

# Create a daily cost check script
cat > check_cost.sh << 'EOF'
#!/bin/bash
COST=$(aws ce get-cost-and-usage \
  --time-period Start=$(date -u -d '1 day ago' +%Y-%m-%d),End=$(date -u +%Y-%m-%d) \
  --granularity DAILY \
  --metrics BlendedCost \
  --query 'ResultsByTime[0].Total.BlendedCost.Amount' \
  --output text)

echo "Yesterday's cost: \$$COST"

if (( $(echo "$COST > 5" | bc -l) )); then
  echo "⚠️ WARNING: Daily cost exceeds $5!"
fi
EOF

chmod +x check_cost.sh
./check_cost.sh
```

**Run this every morning!**

---

## ✅ SUCCESS = STAYING IN BUDGET + LEARNING FINOPS

The goal is NOT to spend $0. The goal is to:
1. Build a real project (some cost is expected)
2. Understand what each service costs
3. Make informed cost decisions
4. Demonstrate FinOps thinking

**In interviews, talk about:**
- How you tracked costs daily
- How you optimized (Spot, tear-down, right-sizing)
- How you balanced cost vs functionality
- What you'd do differently with a bigger budget
- How you'd scale cost-effectively

This FinOps discipline is what companies want in Senior DevOps roles.

---

**Tomorrow, tell me:**
"My current AWS spend is $X.XX. I am in the [Green/Yellow/Orange/Red] zone."

I'll help you optimize if needed. 💰