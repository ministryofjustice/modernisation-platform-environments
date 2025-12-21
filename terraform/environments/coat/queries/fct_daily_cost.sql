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
  resource_tags['application'] as tag_application,
  resource_tags['namespace'] as tag_namespace,
  resource_tags['environment'] as tag_environment,
  resource_tags['service_area'] as tag_service_area,
  resource_tags['owner'] as tag_owner,
  product['product_name'] as product_name,
  date(line_item_usage_start_date) as usage_date,

  sum(line_item_net_unblended_cost) as sum_net_unblended_cost,

  billing_period
from data
group by
  billing_period,
  line_item_usage_account_name,
  product_region_code,
  cost_category['environment'],
  cost_category['business_unit'],
  resource_tags['application'],
  resource_tags['namespace'],
  resource_tags['environment'],
  resource_tags['service_area'],
  resource_tags['owner'],
  product['product_name'],
  date(line_item_usage_start_date);