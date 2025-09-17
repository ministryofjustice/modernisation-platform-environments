locals {
  alpha_user_permissions = local.is-development ? [] : [
    # {
    #   username  = "matt-heery"
    #   databases = [{ derived = ["visits"] }]
    # },
    # {
    #   username  = "mrixson-moj"
    #   databases = [{ derived = ["visits"] }]
    # }
  ]
  alpha_user_permissions_no_filter = local.is-production ? [
    {
      username  = "arjunkhetia66"
      databases = [{ g4s_gps = ["read_g4s_gps_xlsx"] }]
    },
    {
      username  = "chris-wheatley"
      databases = [{ g4s_gps = ["read_g4s_gps_xlsx"] }]
    },
    {
      username  = "evincent-moj"
      databases = [{ g4s_gps = ["read_g4s_gps_xlsx"] }]
    }
  ] : []
}

resource "aws_lakeformation_permissions" "share_data_bucket_alpha_users" {
  for_each = local.is-development ? [] : toset(flatten([
    for details in local.alpha_user_permissions : [details.username]
  ]))

  principal   = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/alpha_user_${each.value}"
  permissions = ["DATA_LOCATION_ACCESS"]
  data_location {
    arn = aws_lakeformation_resource.data_bucket.arn
  }
}

resource "aws_lakeformation_permissions" "share_database_describe_alpha_users" {
  for_each = local.is-production ? {
    for permission in flatten([
      for user in local.alpha_user_permissions_no_filter : [
        for db in user.databases : [
          for db_key, tables in db : [
            {
              username     = user.username
              database_key = db_key
            }
          ]
        ]
      ]
    ]) : "${permission.username}-${permission.database_key}" => permission
  } : {}
  principal   = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/alpha_user_${each.value.username}"
  permissions = ["DESCRIBE"]
  database {
    name = "${each.value.database_key}${local.dbt_suffix}"
  }
}

resource "aws_lakeformation_permissions" "share_table_describe_alpha_users" {
  for_each = local.is-production ? {
    for permission in flatten([
      for user in local.alpha_user_permissions : [
        for db in user.databases : [
          for db_key, tables in db : [
            for table_name in tables : {
              username     = user.username
              database_key = db_key
              table_name   = table_name
            }
          ]
        ]
      ]
    ]) : "${permission.username}-${permission.database_key}-${permission.table_name}" => permission
  } : {}
  principal   = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/alpha_user_${each.value.username}"
  permissions = ["DESCRIBE"]

  table {
    database_name = "${each.value.database_key}${local.dbt_suffix}"
    name          = each.value.table_name
  }
}

resource "aws_lakeformation_permissions" "share_table_describe_alpha_users_no_filter" {
  for_each = local.is-development ? {} : {
    for permission in flatten([
      for user in local.alpha_user_permissions_no_filter : [
        for db in user.databases : [
          for db_key, tables in db : [
            for table_name in tables : {
              username     = user.username
              database_key = db_key
              table_name   = table_name
            }
          ]
        ]
      ]
    ]) : "${permission.username}-${permission.database_key}-${permission.table_name}" => permission
  }
  principal   = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/alpha_user_${each.value.username}"
  permissions = ["SELECT"]

  table {
    database_name = "${each.value.database_key}${local.dbt_suffix}"
    name          = each.value.table_name
  }
}

resource "aws_lakeformation_permissions" "share_table_filter_describe_alpha_users" {
  for_each = local.is-development ? {} : {
    for permission in flatten([
      for user in local.alpha_user_permissions : [
        for db in user.databases : [
          for db_key, tables in db : [
            for table_name in tables : {
              username     = user.username
              database_key = db_key
              table_name   = table_name
            }
          ]
        ]
      ]
    ]) : "${permission.username}-${permission.database_key}-${permission.table_name}" => permission
  }
  principal   = "arn:aws:iam::${local.environment_management.account_ids["analytical-platform-data-production"]}:role/alpha_user_${each.value.username}"
  permissions = ["SELECT"]

  data_cells_filter {
    database_name    = "${each.value.database_key}${local.dbt_suffix}"
    table_name       = each.value.table_name
    name             = "${each.value.table_name}_general_filter"
    table_catalog_id = data.aws_caller_identity.current.account_id
  }
}
