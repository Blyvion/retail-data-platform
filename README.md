# Snowflake + dbt + Airflow Data Engineering Pipeline

This project demonstrates a modern data engineering workflow using **Snowflake, dbt, Apache Airflow, and AWS-based cloud infrastructure**.

The project is based in part on Snowflake's [Data Engineering with Apache Airflow](https://www.snowflake.com/en/developers/guides/data-engineering-with-apache-airflow/#overview) guide and expands on that workflow by incorporating data modeling, testing, dimensional modeling concepts, and pipeline orchestration.

## Architecture

The technology stack used in this project is:

```text
Raw Data
   │
   ▼
Snowflake
   │
   ▼
dbt
   │
   ▼
Apache Airflow
   │
   ▼
Analytics-Ready Data
```

The primary technologies serve different roles within the pipeline:

- **Snowflake** provides the cloud data platform used to store and process the project's data.
- **dbt (Data Build Tool)** manages SQL-based transformations inside Snowflake. It allows transformations to be organized as reusable models while also providing dependency management, documentation, and automated data testing.
- **Apache Airflow** orchestrates the pipeline. Airflow determines when transformations run, manages dependencies between tasks, schedules workflows, and provides monitoring for pipeline execution.
- **AWS** provides cloud infrastructure used by components of the overall environment.

Together, these technologies create a workflow in which raw data is loaded into Snowflake, transformed and validated with dbt, and orchestrated through Airflow.

---

# Project Setup

## Prerequisites

The development environment for this project uses Linux and Python.

You will need:

- Python
- Python virtual environment
- Snowflake account
- dbt Core
- dbt Snowflake adapter
- Astronomer CLI
- Docker

A Snowflake trial account can be used for development and experimentation.

## Python Environment

Create a Python virtual environment:

```bash
python3 -m venv .venv
```

Activate it:

```bash
source .venv/bin/activate
```

Install dbt Core and the Snowflake adapter:

```bash
pip install dbt-core dbt-snowflake
```

The Astronomer CLI is used to run and develop Apache Airflow locally.

Follow Astronomer's installation instructions for your operating system.

---

# Snowflake Configuration

Before initializing the dbt project, configure the Snowflake environment.

The following objects are used throughout this project:

| Object    | Example Name |
| --------- | ------------ |
| Role      | `DBT_ROLE`   |
| Warehouse | `DBT_WH`     |
| Database  | `DBT_DB`     |
| Schema    | `DBT_SCHEMA` |

## Snowflake Setup

Create or configure the following:

1. Create a Snowflake user, or use an existing user.
2. Create a role that will be used by dbt.

```text
DBT_ROLE
```

3. Create a Snowflake warehouse.

```text
DBT_WH
```

4. Create the project database.

```text
DBT_DB
```

5. Grant `DBT_ROLE` to the Snowflake user.
6. Grant the appropriate database privileges to `DBT_ROLE`.
7. Grant warehouse usage privileges to `DBT_ROLE`.
8. Create the project's schema.

```text
DBT_SCHEMA
```

The schema should be created using or assigned to `DBT_ROLE` so that dbt has the permissions necessary to create and modify objects within the schema.

Once Snowflake is configured, initialize the dbt and Airflow development environment.

See Snowflake's [environment setup guide](https://www.snowflake.com/en/developers/guides/data-engineering-with-apache-airflow/#set-up-of-environment) for additional configuration details.

---

# Data Pipeline

The project follows a traditional ETL/ELT-style workflow:

```text
Extract / Ingest
       │
       ▼
   Raw Tables
       │
       ▼
 dbt Sources
       │
       ▼
Staging Models
       │
       ▼
Intermediate Models
       │
       ▼
Fact + Dimension Models
       │
       ▼
Analytics / Reporting
```

Snowflake performs much of the computational work, while dbt defines the SQL transformations executed against the Snowflake warehouse.

Airflow orchestrates when those transformations and related pipeline tasks execute.

---

# Loading Data into Snowflake

Loading the source data into Snowflake represents the ingestion portion of the pipeline.

Before transformations can occur, the raw data must first be made available inside Snowflake.

For this project, data is loaded using:

- Snowflake stages
- Snowflake file formats
- `COPY INTO`

A Snowflake **file format** defines how Snowflake should interpret an incoming file.

For example, CSV configuration can specify:

- field delimiter
- record delimiter
- header handling
- quoting behavior
- null values
- date formats
- encoding

Once the file format and stage are configured, the `COPY INTO` command can load the raw files into Snowflake tables.

Example workflow:

```text
CSV Files
   │
   ▼
Snowflake Stage
   │
   ▼
File Format
   │
   ▼
COPY INTO
   │
   ▼
Raw Snowflake Tables
```

The raw tables become the source layer consumed by dbt.

---

# Dataset

This project uses the **Synthetic Retail Dataset – 1.2M Transactions** dataset from Kaggle:

[https://www.kaggle.com/datasets/amirkhanh/synthetic-retail-dataset-1-2m-transactions](https://www.kaggle.com/datasets/amirkhanh/synthetic-retail-dataset-1-2m-transactions)

The dataset contains retail-related data that can be modeled into analytical fact and dimension tables.

The dimensional modeling approach used in this project is influenced by concepts from the [Kimball Group](https://www.kimballgroup.com/).

---

# Data Modeling

The raw dataset does not enforce a complete relational schema or ERD.

Part of the project therefore involves identifying and validating relationships between entities.

Potential relationships include:

```text
Customer
    │
    ▼
  Sales
    ▲
    │
  Store

SKU ─────► Sales

SKU ─────► Inventory ◄───── Store
```

These relationships can be validated using dbt tests.

For example, a relationship test can ensure that every `store_id` appearing in an inventory table also exists in the stores table.

```yaml
- name: store_id
  tests:
    - not_null
    - relationships:
        to: ref('stores')
        field: store_id
```

This allows dbt to detect broken relationships before invalid data reaches downstream models.

---

# dbt Project Structure

The dbt portion of the project separates transformations into logical layers.

A simplified structure looks like:

```text
models/
│
├── sources/
│   ├── sources.yml
│   ├── stg_sales.sql
│   ├── stg_customers.sql
│   ├── stg_stores.sql
│   ├── stg_skus.sql
│   └── stg_inventory.sql
│
├── intermediate/
│   └── ...
│
└── marts/
    ├── dimensions/
    │   └── ...
    │
    └── facts/
        └── ...
```

Each layer serves a different purpose.

---

## Sources

The **source layer** represents the raw Snowflake tables consumed by dbt.

Source definitions are typically configured in YAML:

```yaml
sources:
  - name: retail
    database: DBT_DB
    schema: DBT_SCHEMA

    tables:
      - name: sales
      - name: customers
      - name: stores
      - name: skus
      - name: inventory
```

These definitions allow dbt to reference raw Snowflake tables using:

```sql
{{ source('retail', 'sales') }}
```

instead of hard-coding database and schema names throughout the project.

---

# Staging Models

Staging models provide a clean, standardized representation of the raw source data.

The staging layer generally maintains a **1-to-1 relationship with the original source tables** while performing lightweight cleanup such as:

- renaming columns
- converting data types
- standardizing values
- handling null values
- removing unnecessary fields
- normalizing naming conventions

For example:

```sql
select
    customer_id,
    first_name,
    last_name,
    city as customer_city
from {{ source('retail', 'customers') }}
```

This creates a stable interface between the raw source data and downstream transformations.

---

# Data Quality Testing

dbt tests are used to validate assumptions about the dataset.

Common tests include:

```yaml
tests:
  - unique
  - not_null
```

Relationship tests can also validate foreign-key-style relationships:

```yaml
tests:
  - relationships:
      to: ref('stg_customers')
      field: customer_id
```

These tests help ensure that downstream fact and dimension tables receive valid data.

Examples of checks performed in this project include:

- primary identifiers should not be null
- identifiers expected to be unique should remain unique
- sales records should reference valid customers
- sales records should reference valid stores
- sales records should reference valid SKUs
- inventory records should reference valid stores and SKUs

This allows data quality problems to be detected before they propagate through the pipeline.

---

# Column Naming

Joining multiple tables can create ambiguous column names.

For example, both the `sales` and `skus` tables may contain:

```text
unit_price
```

Similarly, customer and store data may both contain:

```text
city
```

To avoid ambiguity, columns can be explicitly renamed during transformation.

For example:

```sql
sales.unit_price as sales_unit_price,
skus.unit_price as sku_unit_price,
customers.city as customer_city,
stores.city as store_city
```

Clear naming becomes especially important as models become larger and incorporate data from multiple sources.

---

# Fact and Dimension Tables

The final analytical layer follows dimensional modeling concepts.

A simplified star schema may look like:

```text
                 dim_customer
                       │
                       │
dim_store ──────── fct_sales ──────── dim_sku
                       │
                       │
                    dim_date
```

A second fact table can represent inventory:

```text
dim_store ───── fct_inventory ───── dim_sku
```

### Fact Tables

Fact tables contain measurable business events.

Examples include:

```text
fct_sales
fct_inventory
```

Typical sales measures could include:

```text
quantity
unit_price
revenue
discount
```

### Dimension Tables

Dimension tables provide descriptive information about business entities.

Examples include:

```text
dim_customer
dim_store
dim_sku
dim_date
```

These models make analytical queries significantly easier to construct and maintain.

---

# Surrogate Keys

Dimensional models often use surrogate keys instead of relying entirely on source-system identifiers.

The `dbt_utils` package provides a useful macro for generating deterministic surrogate keys.

Example:

```sql
{{ dbt_utils.generate_surrogate_key([
    'customer_id'
]) }} as customer_key
```

Surrogate keys are particularly useful when creating fact and dimension models because they provide consistent identifiers independent of the source system's original key structure.

---

# Apache Airflow

Once the dbt models and dependencies are defined, Apache Airflow is used to orchestrate the workflow.

Airflow is responsible for tasks such as:

- scheduling pipeline execution
- managing task dependencies
- triggering dbt models
- retrying failed tasks
- monitoring pipeline execution
- recording task logs and run history

Conceptually:

```text
Airflow DAG
    │
    ├── Load Raw Data
    │
    ├── Run dbt Staging Models
    │
    ├── Run dbt Tests
    │
    ├── Run Intermediate Models
    │
    ├── Build Fact + Dimension Models
    │
    └── Run Final Data Quality Tests
```

This separates **transformation logic** from **workflow orchestration**:

```text
dbt      → Defines how the data is transformed
Airflow  → Defines when and in what order those transformations run
Snowflake → Executes and stores the data
```

---

# Project Goals

This project is intended to demonstrate practical experience with technologies commonly used in modern data engineering environments.

Key concepts demonstrated include:

- cloud data warehousing with Snowflake
- SQL-based ELT pipelines
- dbt models and model dependencies
- staging, intermediate, and mart layers
- dimensional data modeling
- fact and dimension tables
- surrogate keys
- automated data quality testing
- referential integrity validation
- Apache Airflow orchestration
- reproducible development environments
- pipeline monitoring and failure detection

The final result is an automated pipeline capable of transforming raw retail transaction data into tested, analytics-ready datasets.

---

# References

- [Snowflake — Data Engineering with Apache Airflow](https://www.snowflake.com/en/developers/guides/data-engineering-with-apache-airflow/#overview)
- [Synthetic Retail Dataset — Kaggle](https://www.kaggle.com/datasets/amirkhanh/synthetic-retail-dataset-1-2m-transactions)
- [Kimball Group — Dimensional Modeling](https://www.kimballgroup.com/)
- [dbt Documentation](https://docs.getdbt.com/)
- [Apache Airflow Documentation](https://airflow.apache.org/docs/)
