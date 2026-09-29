https://www.snowflake.com/en/developers/guides/data-engineering-with-apache-airflow/#overview

The stack we are using looks like aws -> snowflake -> dbt -> airflow
where aws is cloud compute resources, snowflake sits as the manager of those resources and has the capability to also run code on those resources, but we use dbt to write our code so that we can have an environment that auto manages, and tests our "models" (tables and views). airflow sits on top to orchestrate our pipelines after we set them up in dbt, such as scheduling when it should run, triggers, etc.

We have a snowflake account. If not, make one. A trial account is free.
We are developing this on a linux system, so we are creating a python virtual environment and installing dbt using pip. We are then installing the astro cli. 

Setup:
Install dbt-core, dbt-snowflake and astro cli
On snowflake, create the following:
1) Create a user (you can just use your login user)
2) create a role that will have access to the warehouse and database we are going to be working on. (dbt_role)
3) create a warehouse (dbt_wh)
4) create a database (dbt_db)
5) grant the role to the user
6) grant the database to the role
7) grant the warehouse to the role
8) create a schema in the database (dbt_schema, make sure to use the role so that it has correct permissions)

Now [initialize](https://www.snowflake.com/en/developers/guides/data-engineering-with-apache-airflow/#set-up-of-environment) your environment.

## Loading Data into Snowflake

This is the extract portion of the pipeline. You need a way to get the data into a position so that the rest of the pipeline can function.

We have already created the database and schema. We now need to get the data into our snowflake database. There are multiple way to do this. The tool we will be using is file formats and copy into function provided by snowflake. Each file format is unique to the way that the raw data is formatted.

- Data here does not implement erd. its assumed and you will need to verify that there is a relationship using dbt or something else.
- You may need to reorder the columns and you can do this within copy into function or you can create a view after.
- It is good practice to rename the columns to tablename_columnname. That way if you join you dont have to rename columns explicitly.


**Data setup
https://www.kaggle.com/datasets/amirkhanh/synthetic-retail-dataset-1-2m-transactions
https://www.kimballgroup.com/

We have a sources folder in our models. This will act as our staging area for dbt to interact with our tables/models.

###### Sources
this folder is 1 to 1 with the actual source table. you can rename columns if you want. this is also where you establish ERD relationships such as foreign keys and contraints about your data. This verifies the integerity of your data to make sure downstream tasks are getting correct information.

dbt utils has a surrogate key that is useful for fact and dim tables. https://www.kimballgroup.com/




