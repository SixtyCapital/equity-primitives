# Equity Primitives

This repo contains data transformations from standard vendor daily equity
pricing data to structured / modeled / research-ready equity returns data.
It's written in BigQuery SQL, but could be adjusted to other SQL dialects
fairly easily.

As background, we found it surprisingly difficult to generate equity data
"primitives" for researching daily equity returns from vendor daily equity
pricing packages (e.g. FactSet); e.g. split-adjusted total returns, or
returns-above-cash, or USD returns, or reasonable adjustments for holidays,
or market caps.

NB: This repo doesn't contain any actual data, nor does it contain the
scripts to upload the vendor data into BigQuery. In order to run materialize
these queries into tables, we used [Apache
Airflow](https://airflow.apache.org/) scripts (not included here), and
[dbt](https://www.getdbt.com/) could also work.

This was last updated in June 2019, and isn't being actively maintained. That
said, if you have any questions feel free to reach out.