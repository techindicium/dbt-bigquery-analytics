# BigQuery Analytics
## This repository is in experimental stage. It is NOT ready for production.
### Changes are being made.

This package allows you to easily monitor and manage your BigQuery query costs, identifying costly queries in order to enhance optimizing and resource saving.

## Before creating a branch

Pay attention, it is very important to know if your modification to this repository is a release (breaking changes), a feature (functionalities) or a patch(to fix bugs). With that information, create your branch name like this:

- `release/<branch-name>` or `major/<branch-name>` or `Release/<branch-name>` or `Major/<branch-name>`
- `feature/<branch-name>` or `minor/<branch-name>` with capitalised letters work as well
- `patch/<branch-name>` or `fix/<branch-name>` or `hotfix/<branch-name>` with capitalised letters work as well

If branch is already made, just rename it _before passing the pull request_.

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

The package's models can be configured in your `dbt_project.yml` by specifying the package under `models` node. 

The BQ queries's start date you want to monitor also must be declared in vars node. 

We add some other variables to improve your monitoring and management of BigQuery. Some of them are related with dbt. You can add your dbt targets and sources.

It is important to add the exchange rate between USD dollar and BRL real and the price per terabyte processed.

Something important to point out is that the models created by this package are not restrictered to dbt, in this way when the informations about BigQuery have no relation to dbt, you'll see the coluns related to dbt bringing something like `others` or `inaplicable`.

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
  usd_dollars_real: 5.58 # here you can add the price of the dollar in reais
  price_per_tib: 6.25 # here you can add the price per terabyte processed
  dbt_sources: [
      'adw'
      , 'adf'
      , 'databricks_workflow'
  ] # you can configure the sources of your procject here
  ci_dbt_target: 'ci' # add the CI/CD target of your dbt project
  prod_dbt_target: 'prod' # add the development target of your dbt project
  dev_dbt_target: 'dev' # add the production target of your dbt project
  dbt_source_monitoring_dataset: 'raw_monitoring' # if you have one, add a source dataset of your monitoring data
  dbt_prod_monitoring_dataset: 'public_monitoring' # if you have one, add the destination dataset of your monitoring transformed data
```

## Configuring project sources

The project's sources can be configured in your `source.yml`, normally on your staging folder. Attention is needed while naming the source' schema and tables names to ensure you are matching the name BigQuery sets on the and schema and table with your source. If the names match, your package will work as expected.

### Source configuration

```yaml
version: 2

sources:
  - name: bigquery_info_schema
    schema: INFORMATION_SCHEMA
    database: "{{ target.database }}.{{ var('region') }}" ## vars to fit your use case
    tables:
      - name: JOBS
```

## Running the models

After setting up the package in `dbt_project.yml` and `source.yml` as the previous steps, you can now run the package with the following command line: `dbt run -s bigquery_analytics`. After running it, the 5 models of the package will materialize in your target schema as they have been configured.
