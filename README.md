# Payments Analytics dbt Project

A comprehensive dbt transformation project for payments analytics with star schema design and KPI views.

## 📋 Project Overview

This dbt project transforms raw Airbyte CDC data from a PostgreSQL payments database into an analytics-ready BigQuery dataset with:

- **9 Staging Models**: Normalize and deduplicate raw Airbyte data
- **3 Intermediate Models**: Business logic transformations
- **6 Dimension Tables**: Customer, payment method, and date dimensions
- **3 Fact Tables**: Transactions, refunds, and disputes
- **7 KPI Views**: Revenue, customer, payment method, refund, fee, risk, and payout analytics

## 🏗️ Project Structure

```
.
├── dbt_project.yml              # dbt project configuration
├── profiles.yml                 # BigQuery connection configuration
├── keyfile.json                 # BigQuery service account key (git-ignored)
├── README.md                    # This file
│
├── models/
│   ├── sources.yml              # Source definitions for Airbyte raw data
│   ├── schema.yml               # Model documentation and tests
│   │
│   ├── staging/                 # Raw data normalization
│   │   ├── stg_customers.sql
│   │   ├── stg_transactions.sql
│   │   ├── stg_payment_methods.sql
│   │   ├── stg_refunds.sql
│   │   ├── stg_disputes.sql
│   │   ├── stg_fees.sql
│   │   ├── stg_transaction_legs.sql
│   │   ├── stg_mandates.sql
│   │   └── stg_payouts.sql
│   │
│   ├── intermediate/            # Business logic transformations
│   │   ├── int_transactions_with_fees.sql
│   │   ├── int_customer_transactions.sql
│   │   └── int_refund_transactions.sql
│   │
│   ├── marts/                   # Fact and dimension tables
│   │   ├── facts/
│   │   │   ├── fct_transactions.sql     (incremental)
│   │   │   ├── fct_refunds.sql          (incremental)
│   │   │   └── fct_disputes.sql         (incremental)
│   │   └── dimensions/
│   │       ├── dim_customers.sql        (full refresh)
│   │       ├── dim_payment_methods.sql  (full refresh)
│   │       └── dim_dates.sql            (full refresh)
│   │
│   └── views/                   # Analytics KPI views
│       ├── vw_daily_revenue.sql
│       ├── vw_customer_metrics.sql
│       ├── vw_payment_method_performance.sql
│       ├── vw_refund_chargeback_analysis.sql
│       ├── vw_fee_revenue_analysis.sql
│       ├── vw_risk_compliance_dashboard.sql
│       └── vw_payout_metrics.sql
│
├── macros/
│   └── generate_surrogate_key.sql       # Surrogate key generation utility
│
├── tests/                       # dbt tests (add custom tests here)
│
└── analysis/                    # Ad-hoc SQL queries
```

## 🔧 Setup & Configuration

### Prerequisites
- dbt >= 1.0.0
- BigQuery project with appropriate permissions
- Service account key for BigQuery authentication

### Installation

1. **Install dbt** (if not already installed):
   ```bash
   pip install dbt-bigquery
   ```

2. **Configure BigQuery Connection**:
   The `profiles.yml` and `keyfile.json` are already configured via the setup_dbt_bigquery_connection tool.

3. **Verify Configuration**:
   ```bash
   dbt debug
   ```

### Running the Project

```bash
# Compile all models
dbt compile

# Run all models
dbt run

# Run specific models
dbt run --models stg_customers
dbt run --models +fct_transactions+  # Include upstream and downstream

# Run with full refresh (ignore incremental state)
dbt run --full-refresh

# Run tests
dbt test

# Generate documentation
dbt docs generate
dbt docs serve
```

## 📊 Data Model Overview

### Staging Layer (Raw Data Normalization)
Staging models normalize Airbyte CDC data with:
- JSON extraction from `_airbyte_data` field
- Deduplication by keeping latest record
- Type casting to appropriate BigQuery types
- Null handling

**Models**: `stg_customers`, `stg_transactions`, `stg_payment_methods`, `stg_refunds`, `stg_disputes`, `stg_fees`, `stg_transaction_legs`, `stg_mandates`, `stg_payouts`

### Intermediate Layer (Business Logic)
Ephemeral models that apply business transformations:

**int_transactions_with_fees**
- Aggregates fees by type (platform, processing, interchange)
- Calculates net_amount = gross_amount - total_fees
- Classifies fees as low/medium/high based on percentage

**int_customer_transactions**
- Unpivots transactions to customer perspective (1 txn → 2 rows)
- Classifies customer lifecycle stage (new/existing)
- Assesses transaction risk level (critical/elevated/standard)
- Flags compliance review requirements

**int_refund_transactions**
- Joins refunds with original transactions
- Calculates refund percentage and days to refund
- Classifies refund severity and reason category
- Flags suspicious refunds

### Mart Layer (Analytics)

#### Dimension Tables (Full Refresh)
- **dim_customers**: Customer master data with surrogate keys
- **dim_payment_methods**: Payment instrument catalog
- **dim_dates**: Calendar dimension (2024-2030) with date attributes

#### Fact Tables (Incremental)
- **fct_transactions**: Transaction grain with customer context and fee breakdown
- **fct_refunds**: Refund grain with severity and reason classification
- **fct_disputes**: Dispute grain with resolution tracking

### Analytics Views (KPI Layer)

#### 1. **vw_daily_revenue**
Daily revenue metrics by currency and customer type
- Metrics: transaction_count, total_amount, avg_transaction_size, total_fees
- Filters: completed transactions only

#### 2. **vw_customer_metrics**
Customer-level metrics for segmentation and lifetime value
- Metrics: total_transactions, customer_lifetime_value, active_customers_30d
- Dimensions: kyc_status, risk_profile, customer_type, lifecycle_stage

#### 3. **vw_payment_method_performance**
Payment method effectiveness analysis
- Metrics: success_rate, failure_rate, avg_transaction_amount
- Tracks: credit_card, bank_account, digital_wallet performance

#### 4. **vw_refund_chargeback_analysis**
Refund and dispute trend analysis
- Metrics: refund_rate, dispute_rate, avg_refund_amount, resolution_time
- Segments: by reason, by customer, by date

#### 5. **vw_fee_revenue_analysis**
Fee revenue optimization analysis
- Metrics: total_fees, avg_fee_per_transaction, fee_margin, fee_breakdown
- Tracks: platform_fee, processing_fee, interchange_fee

#### 6. **vw_risk_compliance_dashboard**
Risk and compliance monitoring
- Metrics: kyc_verification_rate, high_risk_transaction_volume
- Dimensions: kyc_status, risk_profile, customer_type

#### 7. **vw_payout_metrics**
Payout operations and settlement tracking
- Metrics: total_payouts, success_rate, pending_amount
- Tracks: scheduled vs executed payouts

## 🔑 Key Features

### Data Quality
- **Surrogate Keys**: Generated using MD5 hash for dimension tables
- **Deduplication**: Latest record per natural key in staging
- **Type Safety**: Explicit casting to numeric/timestamp types
- **Null Handling**: Coalesce with defaults in aggregations

### Incremental Loading
Fact tables configured as incremental with:
- `unique_key` enforcement (transaction_id, refund_id, dispute_id)
- `on_schema_change = fail` for safety
- Timestamp-based filtering for efficiency

### Documentation
- Comprehensive column descriptions in schema.yml
- Model-level documentation
- Data lineage captured in dbt_project.yml
- README with setup instructions

### Testing
- **Unique tests**: Primary keys in dimensions and facts
- **Not null tests**: Critical columns
- **Relationship tests**: Foreign key validation
- **Custom tests**: Can be added in tests/ directory

## 📈 Analytics Insights

### Revenue Tracking
Use `vw_daily_revenue` to monitor:
- Daily transaction volume and value
- Average transaction size trends
- Fee collection rates
- Customer type distribution

### Customer Health
Use `vw_customer_metrics` to analyze:
- Customer lifetime value
- Transaction frequency
- Active customer trends
- Customer segmentation by risk/KYC status

### Risk Management
Use `vw_risk_compliance_dashboard` to track:
- KYC verification completion rates
- High-risk transaction volume
- Compliance flag counts
- Risk profile distribution

### Operational Efficiency
Use `vw_payment_method_performance` and `vw_payout_metrics` to optimize:
- Payment method success rates
- Payout settlement times
- Pending payout amounts
- Method-specific failure patterns

## 🔐 Security & Best Practices

### Secrets Management
- `keyfile.json` is git-ignored (included in .gitignore)
- Never commit credentials to version control
- Use environment variables or CI/CD secrets for deployment

### Access Control
- BigQuery service account has minimal required permissions
- Staging schema: read-only access to raw data
- Analytics schema: read access for BI tools
- Marts schema: write access for dbt only

### Data Quality
- Incremental models use unique_key for idempotency
- Staging models deduplicate CDC records
- Tests validate data integrity
- Freshness checks warn on stale data

## 📝 Configuration Variables

Defined in `dbt_project.yml`:

```yaml
vars:
  start_date: '2024-01-01'           # Date dimension start
  end_date: '2030-12-31'             # Date dimension end
  lookback_days: 30                  # Active customer window
  high_risk_threshold: 0.7           # Risk profile threshold
  kyc_verification_threshold: 0.8    # KYC completion target
```

## 🚀 Deployment

### Git Integration
The project is configured with git:
```bash
git add .
git commit -m "Initial payments_analytics dbt project"
git push origin main
```

### CI/CD Integration
For automated deployments:
1. Configure dbt Cloud or GitHub Actions
2. Set BigQuery credentials as secrets
3. Run `dbt test` and `dbt run` on each commit
4. Generate documentation on successful builds

## 📚 Additional Resources

- [dbt Documentation](https://docs.getdbt.com/)
- [BigQuery dbt Adapter](https://docs.getdbt.com/reference/warehouse-setups/bigquery-setup)
- [dbt Best Practices](https://docs.getdbt.com/guides/best-practices)
- [Star Schema Design](https://en.wikipedia.org/wiki/Star_schema)

## 🤝 Contributing

To add new models or views:
1. Create SQL file in appropriate directory (staging/intermediate/marts/views)
2. Add configuration block with materialization type
3. Document columns in schema.yml
4. Add tests for critical columns
5. Test locally: `dbt run --models <new_model>`
6. Run full test suite: `dbt test`

## 📞 Support

For issues or questions:
1. Check dbt logs: `dbt debug`
2. Review model lineage: `dbt docs serve`
3. Test individual models: `dbt run --models <model_name>`
4. Validate data: Check BigQuery console

---

**Project**: payments_analytics v1.0.0  
**Created**: 2026-02-09  
**Last Updated**: 2026-02-09  
**Workspace**: 93  
**Database**: BigQuery (prd-dagen)  
**Target Dataset**: payments_analytics