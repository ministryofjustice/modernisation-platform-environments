import os
import json
import ipaddress
import boto3
from datetime import datetime, timezone, timedelta

STS = boto3.client("sts")
CW  = boto3.client("cloudwatch")

NAMESPACE   = os.getenv("HEALTH_NAMESPACE", "Custom/Health")
ROLE_NAME   = os.getenv("TENANT_ROLE_NAME", "observability-platform-health-signal-reader")
TENANTS_JSON = os.getenv("TENANTS_JSON", "[]")
REGION      = os.getenv("TARGET_REGION", "eu-west-2")

SUBNET_WARN = float(os.getenv("WARN_THRESHOLD", "0.90"))
SUBNET_CRIT = float(os.getenv("CRIT_THRESHOLD", "0.95"))

TELEMETRY_LOOKBACK_MINUTES = int(os.getenv("TELEMETRY_LOOKBACK_MINUTES", "15"))
NAT_LOOKBACK_MINUTES       = int(os.getenv("NAT_LOOKBACK_MINUTES", "15"))
EDGE_LOOKBACK_MINUTES      = int(os.getenv("EDGE_LOOKBACK_MINUTES", "15"))

EDGE_5XX_WARN = float(os.getenv("EDGE_5XX_WARN", "10"))
EDGE_5XX_CRIT = float(os.getenv("EDGE_5XX_CRIT", "50"))

QUOTA_WARN_RATIO = float(os.getenv("QUOTA_WARN_RATIO", "0.80"))
QUOTA_CRIT_RATIO = float(os.getenv("QUOTA_CRIT_RATIO", "0.90"))

def sev_from_ratio(r: float) -> int:
    if r >= QUOTA_CRIT_RATIO:
        return 2
    if r >= QUOTA_WARN_RATIO:
        return 1
    return 0

def severity(utilisation: float) -> int:
    if utilisation >= SUBNET_CRIT:
        return 2
    if utilisation >= SUBNET_WARN:
        return 1
    return 0

def cidr_usable_ipv4(cidr: str) -> int:
    net = ipaddress.ip_network(cidr, strict=False)
    return max(0, net.num_addresses - 5)

def assume_session(account_id: str):
    role_arn = f"arn:aws:iam::{account_id}:role/{ROLE_NAME}"
    resp = STS.assume_role(RoleArn=role_arn, RoleSessionName="op-health-signals")
    c = resp["Credentials"]
    return boto3.Session(
        aws_access_key_id=c["AccessKeyId"],
        aws_secret_access_key=c["SecretAccessKey"],
        aws_session_token=c["SessionToken"],
        region_name=REGION,
    )

def put_metric_data(metric_data):
    for i in range(0, len(metric_data), 20):
        CW.put_metric_data(Namespace=NAMESPACE, MetricData=metric_data[i:i+20])

def publish_domain_health(now, domain, account_id=None, tenant=None, environment=None, value=0):
    dims = [{"Name": "Domain", "Value": domain}]
    if account_id:   dims.append({"Name": "AccountId", "Value": account_id})
    if tenant:       dims.append({"Name": "Tenant", "Value": tenant})
    if environment:  dims.append({"Name": "Environment", "Value": environment})

    CW.put_metric_data(
        Namespace=NAMESPACE,
        MetricData=[{
            "MetricName": "DomainHealth",
            "Dimensions": dims,
            "Timestamp": now,
            "Value": value,
            "Unit": "None",
        }]
    )

def heartbeat(now):
    publish_domain_health(now, domain="signal-pipeline", value=0)

def check_subnet_ip(now, sess, account_id, tenant, environment):
    ec2 = sess.client("ec2")
    paginator = ec2.get_paginator("describe_subnets")

    metric_data = []
    worst = 0

    for page in paginator.paginate():
        for s in page["Subnets"]:
            subnet_id = s["SubnetId"]
            cidr = s.get("CidrBlock")
            available = int(s.get("AvailableIpAddressCount", 0))
            if not cidr:
                continue

            total_usable = cidr_usable_ipv4(cidr)
            if total_usable <= 0:
                continue

            used = max(0, total_usable - available)
            util = used / total_usable
            sev = severity(util)
            worst = max(worst, sev)

            dims = [
                {"Name": "Domain", "Value": "subnet-ip"},
                {"Name": "AccountId", "Value": account_id},
                {"Name": "Tenant", "Value": tenant},
                {"Name": "Environment", "Value": environment},
                {"Name": "SubnetId", "Value": subnet_id},
            ]

            metric_data.append({
                "MetricName": "SubnetIpUtilization",
                "Dimensions": dims,
                "Timestamp": now,
                "Value": util,
                "Unit": "None",
            })
            metric_data.append({
                "MetricName": "SubnetIpPressure",
                "Dimensions": dims,
                "Timestamp": now,
                "Value": sev,
                "Unit": "None",
            })

    # per-tenant rollup
    metric_data.append({
        "MetricName": "DomainHealth",
        "Dimensions": [
            {"Name": "Domain", "Value": "subnet-ip"},
            {"Name": "AccountId", "Value": account_id},
            {"Name": "Tenant", "Value": tenant},
            {"Name": "Environment", "Value": environment},
        ],
        "Timestamp": now,
        "Value": worst,
        "Unit": "None",
    })

    put_metric_data(metric_data)
    return worst

def cw_sum(sess, namespace, metric_name, dims, start, end, period=300):
    cw = sess.client("cloudwatch")
    q = {
        "Id": "m1",
        "MetricStat": {
            "Metric": {
                "Namespace": namespace,
                "MetricName": metric_name,
                "Dimensions": [{"Name": k, "Value": v} for k, v in dims.items()],
            },
            "Period": period,
            "Stat": "Sum",
        },
        "ReturnData": True,
    }
    r = cw.get_metric_data(
        MetricDataQueries=[q],
        StartTime=start,
        EndTime=end,
        ScanBy="TimestampDescending",
        MaxDatapoints=1000,
    )
    vals = r["MetricDataResults"][0].get("Values", [])
    return float(sum(vals)) if vals else 0.0

def check_nat_errors(now, sess, account_id, tenant, environment):
    # NAT Gateway error port allocation (CloudWatch metric)
    start = now - timedelta(minutes=NAT_LOOKBACK_MINUTES)
    end = now

    # We don't know NatGatewayId values without DescribeNatGateways; simplest is:
    # - treat ANY datapoints for ErrorPortAllocation across all NAT gateways as issue by using ListMetrics+per-dimension (more expensive),
    # - OR start with a lighter approach: if you know you have NAT GW metrics, add NAT IDs later.
    #
    # Practical v1: query without dimensions won't work (CloudWatch requires dimensions).
    # So we do DescribeNatGateways to discover NAT IDs and then query each.
    ec2 = sess.client("ec2")
    nat_ids = []
    for page in ec2.get_paginator("describe_nat_gateways").paginate(
        Filter=[{"Name": "state", "Values": ["pending", "available"]}]
    ):
        for ngw in page.get("NatGateways", []):
            nat_ids.append(ngw["NatGatewayId"])

    worst = 0
    total_errors = 0.0

    for nat_id in nat_ids:
        v = cw_sum(
            sess,
            namespace="AWS/NATGateway",
            metric_name="ErrorPortAllocation",
            dims={"NatGatewayId": nat_id},
            start=start,
            end=end,
            period=300,
        )
        total_errors += v
        if v > 0:
            worst = 2  # treat as CRIT; you can soften to WARN if you prefer

    # publish raw + domain health
    metric_data = [{
        "MetricName": "NatErrorPortAllocationSum",
        "Dimensions": [
            {"Name": "Domain", "Value": "nat"},
            {"Name": "AccountId", "Value": account_id},
            {"Name": "Tenant", "Value": tenant},
            {"Name": "Environment", "Value": environment},
        ],
        "Timestamp": now,
        "Value": total_errors,
        "Unit": "Count",
    },{
        "MetricName": "DomainHealth",
        "Dimensions": [
            {"Name": "Domain", "Value": "nat"},
            {"Name": "AccountId", "Value": account_id},
            {"Name": "Tenant", "Value": tenant},
            {"Name": "Environment", "Value": environment},
        ],
        "Timestamp": now,
        "Value": worst,
        "Unit": "None",
    }]
    put_metric_data(metric_data)
    return worst

def check_edge_alb_5xx(now, sess, account_id, tenant, environment):
    # ALB 5xx from CloudWatch, discovered via elbv2 DescribeLoadBalancers
    elb = sess.client("elbv2")
    start = now - timedelta(minutes=EDGE_LOOKBACK_MINUTES)
    end = now

    worst = 0
    total_5xx = 0.0

    paginator = elb.get_paginator("describe_load_balancers")
    for page in paginator.paginate():
        for lb in page.get("LoadBalancers", []):
            # Only Application Load Balancers
            if lb.get("Type") != "application":
                continue

            # CW dimension value is the "LoadBalancer" full name, e.g. app/my-lb/123...
            # AWS returns it in LoadBalancerArn; we need the "LoadBalancerName" form.
            # Conveniently, AWS provides it in the "LoadBalancerArn" only, so we derive full name from the ARN.
            # arn:aws:elasticloadbalancing:region:acct:loadbalancer/app/name/id
            arn = lb["LoadBalancerArn"]
            full_name = arn.split("loadbalancer/")[1]

            v = cw_sum(
                sess,
                namespace="AWS/ApplicationELB",
                metric_name="HTTPCode_ELB_5XX_Count",
                dims={"LoadBalancer": full_name},
                start=start,
                end=end,
                period=300,
            )
            total_5xx += v

    if total_5xx >= EDGE_5XX_CRIT:
        worst = 2
    elif total_5xx >= EDGE_5XX_WARN:
        worst = 1

    metric_data = [{
        "MetricName": "EdgeElb5xxSum",
        "Dimensions": [
            {"Name": "Domain", "Value": "edge"},
            {"Name": "AccountId", "Value": account_id},
            {"Name": "Tenant", "Value": tenant},
            {"Name": "Environment", "Value": environment},
        ],
        "Timestamp": now,
        "Value": total_5xx,
        "Unit": "Count",
    },{
        "MetricName": "DomainHealth",
        "Dimensions": [
            {"Name": "Domain", "Value": "edge"},
            {"Name": "AccountId", "Value": account_id},
            {"Name": "Tenant", "Value": tenant},
            {"Name": "Environment", "Value": environment},
        ],
        "Timestamp": now,
        "Value": worst,
        "Unit": "None",
    }]
    put_metric_data(metric_data)
    return worst

def check_quotas(now, sess, account_id, tenant, environment):
    # v1 quota checks: EIPs and VPCs
    # EIP quota code: L-0263D0A3; VPCs per Region quota code: L-F678F1CE
    sq = sess.client("service-quotas")
    ec2 = sess.client("ec2")

    checks = [
        {"name": "eip", "service_code": "ec2", "quota_code": "L-0263D0A3"},
        {"name": "vpc", "service_code": "vpc", "quota_code": "L-F678F1CE"},
    ]

    # usage
    eips_used = len(ec2.describe_addresses().get("Addresses", []))
    vpcs_used = len(ec2.describe_vpcs().get("Vpcs", []))

    usage_map = {"eip": float(eips_used), "vpc": float(vpcs_used)}

    metric_data = []
    worst = 0

    for c in checks:
        q = sq.get_service_quota(ServiceCode=c["service_code"], QuotaCode=c["quota_code"])
        limit = float(q["Quota"]["Value"])
        used = usage_map[c["name"]]
        ratio = (used / limit) if limit > 0 else 0.0
        s = sev_from_ratio(ratio)
        worst = max(worst, s)

        dims = [
            {"Name": "Domain", "Value": "quotas"},
            {"Name": "AccountId", "Value": account_id},
            {"Name": "Tenant", "Value": tenant},
            {"Name": "Environment", "Value": environment},
            {"Name": "Quota", "Value": c["name"]},
        ]

        metric_data.append({
            "MetricName": "QuotaUsageRatio",
            "Dimensions": dims,
            "Timestamp": now,
            "Value": ratio,
            "Unit": "None",
        })

    metric_data.append({
        "MetricName": "DomainHealth",
        "Dimensions": [
            {"Name": "Domain", "Value": "quotas"},
            {"Name": "AccountId", "Value": account_id},
            {"Name": "Tenant", "Value": tenant},
            {"Name": "Environment", "Value": environment},
        ],
        "Timestamp": now,
        "Value": worst,
        "Unit": "None",
    })

    put_metric_data(metric_data)
    return worst

def check_telemetry(now, sess, account_id, tenant, environment):
    # Practical v1 “freshness”: ensure we can see *some* CloudWatch datapoints
    # We use NAT errors + ALB 5xx + subnet metric publishing as signals indirectly.
    # A simple explicit metric-based check:
    # - If tenant has ALBs, query RequestCount; if datapoints exist -> OK.
    # - Else if tenant has NAT gateways, query BytesOutToDestination; if datapoints exist -> OK.
    # - Else -> OK (no known telemetry sources).
    #
    # This avoids false alarms for accounts with no EC2/LB/NAT.
    elb = sess.client("elbv2")
    ec2 = sess.client("ec2")

    start = now - timedelta(minutes=TELEMETRY_LOOKBACK_MINUTES)
    end = now

    # Try ALB RequestCount
    has_alb = False
    paginator = elb.get_paginator("describe_load_balancers")
    for page in paginator.paginate():
        for lb in page.get("LoadBalancers", []):
            if lb.get("Type") == "application":
                has_alb = True
                arn = lb["LoadBalancerArn"]
                full_name = arn.split("loadbalancer/")[1]
                v = cw_sum(
                    sess,
                    namespace="AWS/ApplicationELB",
                    metric_name="RequestCount",
                    dims={"LoadBalancer": full_name},
                    start=start,
                    end=end,
                    period=300,
                )
                if v > 0:
                    publish_domain_health(now, "telemetry", account_id, tenant, environment, 0)
                    return 0

    # Try NAT BytesOutToDestination
    nat_ids = []
    for page in ec2.get_paginator("describe_nat_gateways").paginate(
        Filter=[{"Name": "state", "Values": ["pending", "available"]}]
    ):
        for ngw in page.get("NatGateways", []):
            nat_ids.append(ngw["NatGatewayId"])

    for nat_id in nat_ids:
        v = cw_sum(
            sess,
            namespace="AWS/NATGateway",
            metric_name="BytesOutToDestination",
            dims={"NatGatewayId": nat_id},
            start=start,
            end=end,
            period=300,
        )
        if v > 0:
            publish_domain_health(now, "telemetry", account_id, tenant, environment, 0)
            return 0

    # If tenant has ALBs or NATs but no datapoints, that’s suspicious.
    if has_alb or nat_ids:
        publish_domain_health(now, "telemetry", account_id, tenant, environment, 1)
        return 1

    # Nothing to check => OK
    publish_domain_health(now, "telemetry", account_id, tenant, environment, 0)
    return 0

def lambda_handler(event, context):
    tenants = json.loads(TENANTS_JSON)
    now = datetime.now(timezone.utc)

    # Always publish heartbeat first
    heartbeat(now)

    for t in tenants:
        account_id  = t["account_id"]
        tenant      = t.get("tenant", "unknown")
        environment = t.get("environment", "unknown")

        sess = assume_session(account_id)

        # Existing + new checks
        check_subnet_ip(now, sess, account_id, tenant, environment)
        check_nat_errors(now, sess, account_id, tenant, environment)
        check_edge_alb_5xx(now, sess, account_id, tenant, environment)
        check_quotas(now, sess, account_id, tenant, environment)
        check_telemetry(now, sess, account_id, tenant, environment)

    return {"status": "ok", "tenants_processed": len(tenants)}
