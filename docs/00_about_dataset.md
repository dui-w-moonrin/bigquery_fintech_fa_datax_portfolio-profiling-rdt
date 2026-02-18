> About Dataset
> Dataset: cloud-training-demos.fintech
> 
> This dataset, hosted on BigQuery, is designed for financial technology (fintech) training and analysis. It comprises six interconnected tables, each providing detailed insights into various aspects of customer loans, loan purposes, and regional distributions. The dataset is ideal for practicing SQL queries, building data models, and conducting financial analytics.
> 
> Tables:
> customer:
> Contains records of individual customers, including demographic details and unique customer IDs. This table serves as a primary reference for analyzing customer behavior and loan distribution.

> loan:
> Includes detailed information about each loan issued, such as the loan amount, interest rate, and tenure. The table is crucial for analyzing lending patterns and financial outcomes.
> 
> loan_count_by_year:
> Provides aggregated loan data by year, offering insights into yearly lending trends. This table helps in understanding the temporal dynamics of loan issuance.
> 
> loan_purposes:
> Lists various reasons or purposes for which loans were issued, along with corresponding loan counts. This data can be used to analyze customer needs and market demands.
> 
> loan_with_region:
> Combines loan data with regional information, allowing for geographical analysis of lending activities. This table is key for regional market analysis and understanding how loan distribution varies across different areas.
> 
> state_region:
> Maps state names to their respective regions, enabling a more granular geographical analysis when combined with other tables in the dataset.
> 
> Use Cases:
> Customer Segmentation: Analyze customer data to identify distinct segments based on demographics and loan behaviors.
> Loan Analysis: Explore loan issuance patterns, interest rates, and purposes to uncover trends and insights.
> Regional Analysis: Combine loan and region data to understand how loan distributions vary by geography.
> Temporal Trends: Utilize the loan_count_by_year table to observe how lending patterns evolve over time.
> This dataset is ideal for those looking to enhance their skills in SQL, financial data analysis, and BigQuery, providing a comprehensive foundation for fintech-related projects and case studies.
source: https://www.kaggle.com/datasets/mustafakeser4/bigquery-fintech-dataset

# BigQuery Fintech Dataset (Local Postgres Mirror)

This repo mirrors a public fintech-style dataset into **PostgreSQL** so we can run:
- Data profiling (scorecards)
- Data validation checks (RDT-ish)
- Reconciliation-style sanity checks

---

## Source

- BigQuery public dataset: `cloud-training-demos.fintech`

> Note: In this repo we treat it as a **training dataset**.
> All rules/assumptions are documented explicitly in SQL and markdown.

---

## Tables (high level)

Typical entities you will see in this dataset:
- Customers
- Loans
- Payments / Transactions (depending on the subset used)

---

## What "RDT-ish" means here

We use simple, auditable rules similar in spirit to regulatory data work:
- Clear **definitions** (valid/missing/mismatched)
- Locked **allowed sets** for enums
- Locked **patterns** for IDs/codes
- Numeric parsing + basic sanity checks
- Outputs that can become a **scorecard CSV** later

---

## Repo artifacts

- `customer_profiling.sql`  
  Column-level scorecard for `raw.customers` (text + numeric stats)

- `customer_set_top_20.sql`  
  Quick top-N distribution helper for categorical columns

- `01_customers_profiling.md`  
  Human-readable report format for the customer scorecard

