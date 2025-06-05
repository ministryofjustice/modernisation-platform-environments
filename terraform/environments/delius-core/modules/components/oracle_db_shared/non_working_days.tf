# We need to be able to detect non-working days to avoid toggling FSFO on those dates.
# Non-working days for Probation are stored in the DELIUS_APP_SCHEMA.R_STANDARD_REFERENCE_LIST
# table.   However it is not possible to query this if the database is down (for
# example, when it IS a non-working day).   Therefore we copy this data into a DynamoDB table
# where it is accessible at all times.
resource "aws_dynamodb_table" "non_working_days" {
  name         = "${var.env_name}-non-working-days"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "code_value"

  attribute {
    name = "code_value"
    type = "S"
  }

  tags = merge({Name = "NonWorkingDaysTable"},var.tags)
}