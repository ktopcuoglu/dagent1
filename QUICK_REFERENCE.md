# Payments Analytics dbt Project - Quick Reference Card

## 🚀 Quick Commands

```bash
# Navigate to project
cd /tmp/workspace_93/dbt/dagent1

# Verify setup
dbt debug

# Compile models
dbt compile

# Run all models (incremental)
dbt run

# Run all models (full refresh)
dbt run --full-refresh

# Run specific model
dbt run --models stg_customers

# Run with dependencies
dbt run --models +fct_transactions+

# Run tests
dbt test

# Generate docs
dbt docs generate && dbt docs serve

# List all models
dbt ls

# Show model dependencies
dbt ls --graph
```

---

## 📊 Model Overview

### Staging (9 views)
```
stg_customers, stg_transactions, stg_payment_methods, 
stg_refunds, stg_disputes, stg_fees, stg_transaction_legs,
stg_mandates, stg_payouts
```

### Intermediate (3 ephemeral)
```
int_transactions_with_fees, int_customer_transactions,
int_refund_transactions
```

### Dimensions (3 tables)
```
dim_customers, dim_payment_methods, dim_dates
```

### Facts (3 incremental tables)
```
fct_transactions, fct_refunds, fct_disputes
```

### Views (7 KPI views)
```
vw_daily_revenue, vw_customer_metrics,
vw_payment_method_performance, vw_refund_chargeback_analysis,
vw_fee_revenue_analysis, vw_risk_compliance_dashboard,
vw_payout_metrics
```

---

## 🔍 BigQuery Verification

### Check Datasets
```sql
SELECT dataset_id FROM `prd-dagen.region-us`.INFORMATION_SCHEMA.SCHEMATA
WHERE dataset_id IN ('staging', 'analytics', 'marts')
```

### Count Records
```sql
-- Staging
SELECT 'stg_customers' as model, COUNT(*) FROM `prd-dagen.staging.stg_customers`
UNION ALL
SELECT 'stg_transactions', COUNT(*) FROM `prd-dagen.staging.stg_transactions`
UNION ALL
SELECT 'stg_payment_methods', COUNT(*) FROM `prd-dagen.staging.stg_payment_methods`
-- ... etc for other staging models

-- Dimensions
SELECT 'dim_customers' as model, COUNT(*) FROM `prd-dagen.marts.dim_customers`
UNION ALL
SELECT 'dim_payment_methods', COUNT(*) FROM `prd-dagen.marts.dim_payment_methods`
UNION ALL
SELECT 'dim_dates', COUNT(*) FROM `prd-dagen.marts.dim_dates`

-- Facts
SELECT 'fct_transactions' as model, COUNT(*) FROM `prd-dagen.marts.fct_transactions`
UNION ALL
SELECT 'fct_refunds', COUNT(*) FROM `prd-dagen.marts.fct_refunds`
UNION ALL
SELECT 'fct_disputes', COUNT(*) FROM `prd-dagen.marts.fct_disputes`
```

### Sample KPI Views
```sql
SELECT * FROM `prd-dagen.analytics.vw_daily_revenue` LIMIT 10;
SELECT * FROM `prd-dagen.analytics.vw_customer_metrics` LIMIT 10;
SELECT * FROM `prd-dagen.analytics.vw_payment_method_performance` LIMIT 10;
SELECT * FROM `prd-dagen.analytics.vw_refund_chargeback_analysis` LIMIT 10;
SELECT * FROM `prd-dagen.analytics.vw_fee_revenue_analysis` LIMIT 10;
SELECT * FROM `prd-dagen.analytics.vw_risk_compliance_dashboard` LIMIT 10;
SELECT * FROM `prd-dagen.analytics.vw_payout_metrics` LIMIT 10;
```

---

## 🔧 Configuration Files

### dbt_project.yml
- Project name: `payments_analytics`
- Profile: `payments_analytics`
- Models materialization settings
- Variable definitions

### profiles.yml
- BigQuery connection: `payments_analytics`
- Project: `prd-deren`
- Dataset: `sample_k_r_at_top_uo_lu_20260208231623`
- Service account: `keyfile.json`

### sources.yml
- 9 Airbyte raw sources defined
- Freshness checks configured
- Column descriptions

### schema.yml
- 25+ models documented
- Column descriptions
- Tests (unique, not_null, relationships)

---

## 📈 KPI Views Reference

| View | Grain | Key Metrics |
|------|-------|-------------|
| vw_daily_revenue | Day × Currency × Customer Type | total_amount, transaction_count, avg_size |
| vw_customer_metrics | Customer | lifetime_value, total_transactions |
| vw_payment_method_performance | Payment Method | success_rate, avg_amount, volume |
| vw_refund_chargeback_analysis | Day × Reason | refund_rate, dispute_rate, avg_amount |
| vw_fee_revenue_analysis | Day × Currency | total_fees, avg_fee, fee_margin |
| vw_risk_compliance_dashboard | Risk Level × KYC Status | kyc_rate, high_risk_volume |
| vw_payout_metrics | Day × Status | total_payouts, success_rate |

---

## 🧪 Testing

```bash
# Run all tests
dbt test

# Test specific model
dbt test --models fct_transactions

# Test specific test type
dbt test --select unique_*
dbt test --select not_null_*

# Test with details
dbt test --debug
```

---

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| "Profile not found" | Check profiles.yml in project root |
| "Permission denied" | Verify service account has BigQuery Editor role |
| "Table not found" | Run staging models first: `dbt run --models staging` |
| "Duplicates in facts" | Check unique_key constraint, verify data clean |
| "Test failures" | Run `dbt test --debug` for details |
| "Slow queries" | Check BigQuery console, add clustering/partitioning |

---

## 📚 Documentation Files

- **README.md** - Full project documentation
- **IMPLEMENTATION_SUMMARY.md** - Technical specifications
- **EXECUTION_GUIDE.md** - Step-by-step execution guide
- **PROJECT_COMPLETION_REPORT.md** - Completion status
- **QUICK_REFERENCE.md** - This file

---

## 🎯 Typical Workflow

```bash
# 1. Setup (first time)
cd /tmp/workspace_93/dbt/dagent1
dbt debug
dbt run --full-refresh
dbt test
dbt docs generate

# 2. Daily run
dbt run
dbt test

# 3. Check results
# Open BigQuery console
# Query analytics schema for KPI views

# 4. Connect BI tool
# Point to analytics schema
# Create dashboards from KPI views
```

---

## 💾 File Locations

```
Project Root: /tmp/workspace_93/dbt/dagent1/

Key Files:
- dbt_project.yml          (configuration)
- profiles.yml             (BigQuery connection)
- keyfile.json             (service account key)
- README.md                (documentation)

Models:
- models/sources.yml       (source definitions)
- models/schema.yml        (model documentation)
- models/staging/          (9 staging models)
- models/intermediate/     (3 intermediate models)
- models/marts/            (6 fact/dimension tables)
- models/views/            (7 KPI views)

Utilities:
- macros/                  (utility macros)
```

---

## 🔐 Security Reminders

- ✅ Never commit keyfile.json or profiles.yml
- ✅ Both files are in .gitignore
- ✅ Use environment variables for credentials in CI/CD
- ✅ Service account has minimal required permissions
- ✅ BigQuery IAM controls data access

---

## 📞 Quick Help

**dbt Docs**: https://docs.getdbt.com/  
**BigQuery Docs**: https://cloud.google.com/bigquery/docs  
**dbt Community**: https://www.getdbt.com/community  

---

## 🏁 Status

**Project**: payments_analytics v1.0.0  
**Status**: ✅ Ready for Production  
**Models**: 25 (all created and tested)  
**Views**: 7 KPI views ready for BI tools  
**Documentation**: Comprehensive  

---

**Ready to run?**
```bash
cd /tmp/workspace_93/dbt/dagent1 && dbt run
```

---

Last Updated: 2026-02-09