locals {
  athena_query_bucket_name = "mojap-next-poc-athena-query"
  datastore_bucket_name    = "mojap-next-poc-data"
  hub_account_id           = local.environment_management.account_ids["analytical-platform-next-poc-hub-development"]

  test_data_csv = "https://factprod.blob.core.windows.net/csv/courts-and-tribunals-data.csv"

  databases = {
    wildcard_db = {
      tables = [
        "alpha_tbl",
        "bravo_tbl",
        "charlie_tbl",
      ]
    }
    individual_db = {
      tables = [
        "shared_tbl",
        "not_shared_tbl",
      ]
    }
  }

  s3_prefixes = flatten([
    for db_name, db in local.databases : [
      for tbl in db.tables : {
        database = db_name
        table    = tbl
      }
    ]
  ])
}
