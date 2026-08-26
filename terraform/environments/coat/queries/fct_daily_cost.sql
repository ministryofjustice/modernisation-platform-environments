create table fct_daily_cost 
with (
  external_location = 's3://${bucket}/ctas/fct-daily-cost/',
  format = 'PARQUET',
  partitioned_by = ARRAY['billing_period']
)
as select
  line_item_usage_account_name as account_name,
  product_region_code,
  cost_category['environment'] as environment,
  cost_category['business_unit'] as business_unit,
  resource_tags['user_application'] as tag_application,
  resource_tags['user_namespace'] as tag_namespace,
  resource_tags['user_environment_name'] as tag_environment,
  resource_tags['user_service_area'] as tag_service_area,
  resource_tags['user_owner'] as tag_owner,
  product['product_name'] as product_name,
  date(line_item_usage_start_date) as usage_date,

  sum(line_item_net_unblended_cost) as daily_cost,

  billing_period
from data
group by
  billing_period,
  line_item_usage_account_name,
  product_region_code,
  cost_category['environment'],
  cost_category['business_unit'],
  resource_tags['user_application'],
  resource_tags['user_namespace'],
  resource_tags['user_environment_name'],
  resource_tags['user_service_area'],
  resource_tags['user_owner'],
  product['product_name'],
  date(line_item_usage_start_date);