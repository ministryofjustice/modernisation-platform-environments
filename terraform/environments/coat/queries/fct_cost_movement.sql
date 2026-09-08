create table fct_cost_movement
with (
  external_location = 's3://${bucket}/ctas/fct-cost-movement/',
  format = 'PARQUET',
  partitioned_by = ARRAY['billing_period']
)
as with usage_cost as (
  select
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
    line_item_line_item_type as charge_type,
    sum(line_item_net_unblended_cost) as daily_cost,
    billing_period
  from data
  where line_item_line_item_type in ('Usage', 'DiscountedUsage', 'SavingsPlanCoveredUsage')
    and billing_period < (select max(billing_period) from data)
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
    line_item_line_item_type
),

monthly_shifted as (
  select
    date_format(
      date_add('month', 1, date_parse(billing_period || '-01', '%Y-%m-%d')),
      '%Y-%m'
    ) as billing_period,
    account_name, product_region_code, environment, business_unit,
    tag_application, tag_namespace, tag_environment, tag_service_area, tag_owner,
    product_name, charge_type,
    daily_cost as prior_cost
  from usage_cost
),

source_bounds as (
  select max(billing_period) as max_billing_period
  from usage_cost
)

select
  coalesce(curr.account_name, prev.account_name) as account_name,
  coalesce(curr.product_region_code, prev.product_region_code) as product_region_code,
  coalesce(curr.environment, prev.environment) as environment,
  coalesce(curr.business_unit, prev.business_unit) as business_unit,
  coalesce(curr.tag_application, prev.tag_application) as tag_application,
  coalesce(curr.tag_namespace, prev.tag_namespace) as tag_namespace,
  coalesce(curr.tag_environment, prev.tag_environment) as tag_environment,
  coalesce(curr.tag_service_area, prev.tag_service_area) as tag_service_area,
  coalesce(curr.tag_owner, prev.tag_owner) as tag_owner,
  coalesce(curr.product_name, prev.product_name) as product_name,
  coalesce(curr.charge_type, prev.charge_type) as charge_type,
  coalesce(curr.daily_cost, 0) as current_cost,
  coalesce(prev.prior_cost, 0) as prior_cost,
  case
    when prev.prior_cost is null or prev.prior_cost = 0 then coalesce(curr.daily_cost, 0)
    else coalesce(curr.daily_cost, 0) - prev.prior_cost
  end as net_change,
  case
    when coalesce(prev.prior_cost, 0) = 0 and coalesce(curr.daily_cost, 0) > 0 then 'new'
    when coalesce(curr.daily_cost, 0) = 0 and coalesce(prev.prior_cost, 0) > 0 then 'removed'
    when coalesce(curr.daily_cost, 0) > coalesce(prev.prior_cost, 0) then 'increased'
    when coalesce(curr.daily_cost, 0) < coalesce(prev.prior_cost, 0) then 'decreased'
    else 'ongoing'
  end as movement_type,
  coalesce(curr.billing_period, prev.billing_period) as billing_period
from usage_cost curr
full outer join monthly_shifted prev
  on coalesce(curr.billing_period, 'UNKNOWN') = coalesce(prev.billing_period, 'UNKNOWN')
  and coalesce(curr.account_name, 'UNKNOWN') = coalesce(prev.account_name, 'UNKNOWN')
  and coalesce(curr.product_region_code, 'UNKNOWN') = coalesce(prev.product_region_code, 'UNKNOWN')
  and coalesce(curr.environment, 'UNKNOWN') = coalesce(prev.environment, 'UNKNOWN')
  and coalesce(curr.business_unit, 'UNKNOWN') = coalesce(prev.business_unit, 'UNKNOWN')
  and coalesce(curr.tag_application, 'UNKNOWN') = coalesce(prev.tag_application, 'UNKNOWN')
  and coalesce(curr.tag_namespace, 'UNKNOWN') = coalesce(prev.tag_namespace, 'UNKNOWN')
  and coalesce(curr.tag_environment, 'UNKNOWN') = coalesce(prev.tag_environment, 'UNKNOWN')
  and coalesce(curr.tag_service_area, 'UNKNOWN') = coalesce(prev.tag_service_area, 'UNKNOWN')
  and coalesce(curr.tag_owner, 'UNKNOWN') = coalesce(prev.tag_owner, 'UNKNOWN')
  and coalesce(curr.product_name, 'UNKNOWN') = coalesce(prev.product_name, 'UNKNOWN')
  and coalesce(curr.charge_type, 'UNKNOWN') = coalesce(prev.charge_type, 'UNKNOWN')
where coalesce(curr.billing_period, prev.billing_period) <= (select max_billing_period from source_bounds);