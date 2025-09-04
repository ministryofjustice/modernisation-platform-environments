locals {
  athena_query_bucket_name = "mojap-next-poc-athena-query"
  datastore_bucket_name    = "mojap-next-poc-data"
  hub_account_id           = local.environment_management.account_ids["analytical-platform-next-poc-hub-development"]

  data = {
    court-locations = {
      # https://www.data.gov.uk/dataset/7e62854a-2926-4f86-bdfb-b88c0800c628/court-locations
      url = "https://factprod.blob.core.windows.net/csv/courts-and-tribunals-data.csv"
    }
    organogram-ministry-of-justice-senior = {
      # https://www.data.gov.uk/dataset/a90a9f70-e28c-4a95-a7a7-f79d12fbe219/organogram-ministry-of-justice
      url = "https://s3-eu-west-1.amazonaws.com/datagovuk-production-ckan-organogram/organogram-ministry-of-justice/resources/2024-10-11T10-24-03Z-2024-10-11-organogram-senior.csv"
    }
    organogram-ministry-of-justice-junior = {
      # https://www.data.gov.uk/dataset/a90a9f70-e28c-4a95-a7a7-f79d12fbe219/organogram-ministry-of-justice
      url = "https://s3-eu-west-1.amazonaws.com/datagovuk-production-ckan-organogram/organogram-ministry-of-justice/resources/2024-10-11T10-24-03Z-2024-10-11-organogram-junior.csv"
    }
  }
}
