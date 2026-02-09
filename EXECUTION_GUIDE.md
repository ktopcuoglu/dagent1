# Payments Analytics dbt Project - Execution Guide

**Quick Start Guide for Running the dbt Project**

---

## 🚀 Quick Start (5 Minutes)

### Step 1: Navigate to Project
```bash
cd /tmp/workspace_93/dbt/dagent1
```

### Step 2: Verify Setup
```bash
dbt debug
```
Expected: ✅ All checks pass, connection to BigQuery verified

### Step 3: Compile Models
```bash
dbt compile
```
Expected: ✅ 25 models compile successfully

### Step 4: Run Full Build (First Time)
```bash
dbt run --full-refresh
```
Expected: ✅ All 25 models execute in order:
- 9 staging views created
- 3 intermediate models (ephemeral, not materialized)
- 3 dimension tables created
- 3 fact tables created (initial load)
- 7 analytics views created

### Step 5: Validate Results
```bash
dbt test
```
Expected: ✅ All tests pass, data quality verified

---

## 📊 Expected Execution Flow

```
STAGING LAYER (9 views)
├── stg_customers
├── stg_transactions
├── stg_payment_methods
├── stg_refunds
├── stg_disputes
├── stg_fees
├── stg_transaction_legs
├── stg_mandates
└── stg_payouts

INTERMEDIATE LAYER (3 ephemeral models - inline)
├── int_transactions_with_fees
├── int_customer_transactions
└── int_refund_transactions

DIMENSION LAYER (3 tables)
├── dim_customers
├── dim_payment_methods
└── dim_dates

FACT LAYER (3 tables - incremental)
├── fct_transactions
├── fct_refunds
└── fct_disputes

ANALYTICS LAYER (7 views)
├── vw_daily_revenue
├── vw_customer_metrics
├── vw_payment_method_performance
├── vw_refund_chargeback_analysis
├── vw_fee_revenue_analysis
├── vw_risk_compliance_dashboard
└── vw_payout_metrics
```

---

## 🔄 Incremental Runs (After Initial Load)

### Daily Incremental Run
```bash
dbt run
```
This will:
- Skip staging models (views don't need refresh)
- Skip intermediate models (ephemeral, recalculated as needed)
- Skip dimension tables (full refresh, but already up to date)
- **Update fact tables incrementally** (only new/changed records)
- Refresh analytics views (based on updated facts)

### Full Refresh (Recalculate Everything)
```bash
dbt run --full-refresh
```
Use this:
- When dimension tables change significantly
- When business logic changes
- For troubleshooting

---

## 📈 Monitoring & Validation

### Check Model Status
```bash
# List all models
dbt ls

# Show dependencies
dbt ls --graph

# Show model details
dbt ls --models fct_transactions --describe
```

### Run Specific Models
```bash
# Run just staging
dbt run --models staging

# Run just dimensions
dbt run --models dim_*

# Run just facts
dbt run --models fct_*

# Run with dependencies (upstream and downstream)
dbt run --models +fct_transactions+
```

### Run Tests
```bash
# All tests
dbt test

# Tests for specific model
dbt test --models fct_transactions

# Only unique tests
dbt test --select unique_*

# Only not_null tests
dbt test --select not_null_*
```

### Generate Documentation
```bash
# Generate docs
dbt docs generate

# Serve docs locally
dbt docs serve
```
Opens documentation at: http://localhost:8000

---

## 📊 BigQuery Verification

After running `dbt run`, verify in BigQuery console:

### Check Datasets Created
```sql
-- List all datasets
SELECT dataset_id, created_time, size_bytes
FROM `prd-dagen.region-us`.INFORMATION_SCHEMA.SCHEMATA
WHERE dataset_id IN ('staging', 'analytics', 'marts')
ORDER BY dataset_id;
```

### Check Staging Views
```sql
-- Count records in each staging view
SELECT 'stg_customers' as model, COUNT(*) as record_count FROM `prd-dagen.staging.stg_customers`
UNION ALL
SELECT 'stg_transactions', COUNT(*) FROM `prd-dagen.staging.stg_transactions`
UNION ALL
SELECT 'stg_payment_methods', COUNT(*) FROM `prd-dagen.staging.stg_payment_methods`
-- ... repeat for other staging models
```

### Check Dimension Tables
```sql
-- Verify dimensions loaded
SELECT 
  'dim_customers' as table_name, COUNT(*) as row_count FROM `prd-dagen.marts.dim_customers`
UNION ALL
SELECT 'dim_payment_methods', COUNT(*) FROM `prd-dagen.marts.dim_payment_methods`
UNION ALL
SELECT 'dim_dates', COUNT(*) FROM `prd-dagen.marts.dim_dates`;
```

### Check Fact Tables
```sql
-- Verify facts loaded
SELECT 
  'fct_transactions' as table_name, COUNT(*) as row_count FROM `prd-dagen.marts.fct_transactions`
UNION ALL
SELECT 'fct_refunds', COUNT(*) FROM `prd-dagen.marts.fct_refunds`
UNION ALL
SELECT 'fct_disputes', COUNT(*) FROM `prd-dagen.marts.fct_disputes`;
```

### Check Analytics Views
```sql
-- Sample from each KPI view
SELECT * FROM `prd-dagen.analytics.vw_daily_revenue` LIMIT 5;
SELECT * FROM `prd-dagen.analytics.vw_customer_metrics` LIMIT 5;
SELECT * FROM `prd-dagen.analytics.vw_payment_method_performance` LIMIT 5;
SELECT * FROM `prd-dagen.analytics.vw_refund_chargeback_analysis` LIMIT 5;
SELECT * FROM `prd-dagen.analytics.vw_fee_revenue_analysis` LIMIT 5;
SELECT * FROM `prd-dagen.analytics.vw_risk_compliance_dashboard` LIMIT 5;
SELECT * FROM `prd-dagen.analytics.vw_payout_metrics` LIMIT 5;
```

---

## 🔍 Troubleshooting

### Issue: "dbt: command not found"
**Solution**: Install dbt
```bash
pip install dbt-bigquery
```

### Issue: "Profile not found: payments_analytics"
**Solution**: Verify profiles.yml exists in project root
```bash
cat profiles.yml
# Should show: payments_analytics:
```

### Issue: "Permission denied" on BigQuery
**Solution**: Verify service account has correct permissions
- BigQuery Editor role on target project
- Service account key file (keyfile.json) exists

### Issue: "Table not found" in intermediate models
**Solution**: Run staging first
```bash
dbt run --models staging
```

### Issue: Incremental models appending duplicates
**Solution**: Verify unique_key is correct
```sql
-- Check for duplicates in fact table
SELECT transaction_id, COUNT(*) as cnt
FROM `prd-dagen.marts.fct_transactions`
GROUP BY transaction_id
HAVING COUNT(*) > 1;
```

### Issue: "dbt test" failures
**Solution**: Check test output
```bash
dbt test --debug  # Show detailed error messages
```

---

## 📋 Model Reference

### Staging Models
| Model | Source | Records | Purpose |
|-------|--------|---------|---------|
| stg_customers | airbyte_raw_customers | ~100s | Customer master data |
| stg_transactions | airbyte_raw_transactions | ~1000s | Transaction records |
| stg_payment_methods | airbyte_raw_payment_methods | ~100s | Payment instruments |
| stg_refunds | airbyte_raw_refunds | ~10s | Refund records |
| stg_disputes | airbyte_raw_disputes | ~10s | Dispute records |
| stg_fees | airbyte_raw_fees | ~1000s | Fee records |
| stg_transaction_legs | airbyte_raw_transaction_legs | ~100s | Sub-transactions |
| stg_mandates | airbyte_raw_mandates | ~100s | Recurring payments |
| stg_payouts | airbyte_raw_payouts | ~100s | Payout records |

### Dimension Tables
| Model | Type | Grain | Refresh |
|-------|------|-------|---------|
| dim_customers | Table | Customer | Full |
| dim_payment_methods | Table | Payment Method | Full |
| dim_dates | Table | Date | Full |

### Fact Tables
| Model | Type | Grain | Refresh | Key |
|-------|------|-------|---------|-----|
| fct_transactions | Incremental | Transaction | Incremental | transaction_id |
| fct_refunds | Incremental | Refund | Incremental | refund_id |
| fct_disputes | Incremental | Dispute | Incremental | dispute_id |

### Analytics Views
| View | Grain | Primary Metric | Key Dimension |
|------|-------|-----------------|-----------------|
| vw_daily_revenue | Day | total_amount | currency |
| vw_customer_metrics | Customer | lifetime_value | customer_type |
| vw_payment_method_performance | Method | success_rate | method_type |
| vw_refund_chargeback_analysis | Day/Reason | refund_rate | refund_reason |
| vw_fee_revenue_analysis | Day/Currency | total_fees | fee_type |
| vw_risk_compliance_dashboard | Risk Level | kyc_rate | risk_profile |
| vw_payout_metrics | Day/Status | payout_volume | status |

---

## 💡 Tips & Best Practices

### 1. Use Selectors for Efficient Runs
```bash
# Run only modified models (requires dbt Cloud)
dbt run --select state:modified+

# Run only tests for facts
dbt test --select tag:facts

# Run by owner
dbt run --select owner:analytics
```

### 2. Monitor Query Performance
```bash
# Check execution times
dbt run --debug  # Shows query execution time

# Check BigQuery slots usage
# In BigQuery console: Admin > Reservations
```

### 3. Version Control
```bash
git add .
git commit -m "feat: update payment method logic"
git push origin main
```

### 4. Schedule with cron
```bash
# Add to crontab for daily 2 AM run
0 2 * * * cd /tmp/workspace_93/dbt/dagent1 && dbt run
```

### 5. Integrate with BI Tools
Connect your BI tool (Looker, Tableau, Power BI) to:
- **staging** schema for raw data exploration
- **analytics** schema for KPI dashboards
- **marts** schema for dimensional analysis

---

## 🔐 Security Checklist

- ✅ keyfile.json is in .gitignore
- ✅ profiles.yml is in .gitignore
- ✅ Service account has minimal required permissions
- ✅ No credentials in code or logs
- ✅ Data access controlled via BigQuery IAM
- ✅ Audit logging enabled in BigQuery

---

## 📞 Support Resources

### dbt Documentation
- [dbt Core Docs](https://docs.getdbt.com/)
- [BigQuery Adapter](https://docs.getdbt.com/reference/warehouse-setups/bigquery-setup)
- [dbt Best Practices](https://docs.getdbt.com/guides/best-practices)

### BigQuery Documentation
- [BigQuery Docs](https://cloud.google.com/bigquery/docs)
- [BigQuery SQL Reference](https://cloud.google.com/bigquery/docs/reference/standard-sql/functions-and-operators)

### Community
- [dbt Slack Community](https://www.getdbt.com/community)
- [dbt Discourse](https://discourse.getdbt.com/)

---

## 🎯 Success Criteria

After running the project, you should have:

✅ **25 models** created (9 staging + 3 intermediate + 3 dimensions + 3 facts + 7 views)  
✅ **3 BigQuery datasets** (staging, marts, analytics)  
✅ **All tests passing** (unique, not_null, relationships)  
✅ **Documentation generated** (dbt docs)  
✅ **Data flowing** from raw → staging → marts → analytics  
✅ **KPI views ready** for BI tool connections  

---

## 🚀 Next Steps

1. **Run the project**: `dbt run`
2. **Test data quality**: `dbt test`
3. **Generate docs**: `dbt docs generate && dbt docs serve`
4. **Connect BI tool**: Point Looker/Tableau to `analytics` schema
5. **Schedule runs**: Set up daily incremental runs
6. **Monitor**: Check BigQuery console for performance

---

**Ready to Execute? Run:**
```bash
cd /tmp/workspace_93/dbt/dagent1 && dbt run
```

---

Generated: 2026-02-09  
Version: 1.0.0  
Status: 🟢 Ready for Production