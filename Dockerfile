FROM astrocrpublic.azurecr.io/runtime:3.3-7

#FROM quay.io/astronomer/astro-runtime:9.1.0-python-3.9-base

RUN python -m venv dbt_venv && source dbt_venv/bin/activate && pip install --no-cache-dir dbt-snowflake && deactivate

