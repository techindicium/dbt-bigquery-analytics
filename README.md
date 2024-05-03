# BigQuery Analytics

This package allows you to easily monitor and manage your BigQuery query costs, identifying costly queries in order to enhance optimizing and resource saving.

# :running: Quickstart

New to dbt packages? Read more about them [here](https://docs.getdbt.com/docs/building-a-dbt-project/package-management/).

## Requirements
dbt version
* ```dbt version >= 1.0.0```

dbt_utils package. Read more about them [here](https://hub.getdbt.com/dbt-labs/dbt_utils/latest/).
* ```dbt-labs/dbt_utils version: 1.1.1```

## Installation

1. Include this package in your `packages.yml` file.
```yaml
packages:
  - git: "git@github.com:techindicium/dbt-bigquery-analytics.git" # insert git URL
```

2. Run `dbt deps` to install the package.



## Configuring models package

The package's models can be configured in your `dbt_project.yml` by specifying the package under `models` node. The BQ queries's start date you want to monitor also must be declared in vars node.

### Models

```yaml
models:
    bigquery_analytics:
        staging:
            materialized: ephemeral
        marts:
            materialized: table
```

### Vars

```yaml
vars:
    dbt_bigquery_analytics:
        bigquery_analytics_start_date: cast('2023-01-01' as date) # inside the double quotes, add the start date of the project
    region: "region-us"
```

## Configuring project sources

The project's sources can be configured in your `source.yml`, normally on your staging folder. Attention is needed while naming the source' schema and tables names to ensure you are matching the name BigQuery sets on the and schema and table with your source. If the names match, your package will work as expected.

### Source configuration

```yaml
sources:
  - name: bigquery_info_schema
    schema: INFORMATION_SCHEMA
    database: "{{ target.database }}.{{ var('region') }}" ## vars to fit your use case
    tables:
      - name: JOBS
```

## Running the models

After setting up the package in `dbt_project.yml` and `source.yml` as the previous steps, you can now run the package with the following command line: `dbt run -m bigquery_analytics`. After running it, the 5 models of the package will materialize in your target schema as they have been configured.