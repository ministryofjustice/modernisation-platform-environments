# Regenerates the General Infrastructure PNG in ./images from the current architecture.
# Only the general-infrastructure diagram uses AWS Architecture Icons — data flow and
# automation diagrams are Mermaid, written directly in 02-data-flow.md.
# Requires: brew install graphviz && pip install diagrams
# Run:      python3 generate.py
import os
from diagrams import Diagram, Cluster, Edge
from diagrams.aws.network import ElbApplicationLoadBalancer, Route53
from diagrams.aws.compute import EC2, Lambda
from diagrams.aws.database import RDSOracleInstance
from diagrams.aws.security import SecretsManager, KMS, ACM, WAF
from diagrams.aws.storage import S3, EBS
from diagrams.aws.integration import SNS
from diagrams.aws.management import SystemsManager
from diagrams.aws.general import User, InternetAlt1

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "images")

GRAPH_ATTR = {
    "splines": "ortho",
    "pad": "0.4",
    "nodesep": "0.55",
    "ranksep": "0.65",
    "fontname": "Helvetica",
}
NODE_ATTR = {"fontname": "Helvetica", "fontsize": "11"}
EDGE_ATTR = {"fontname": "Helvetica", "fontsize": "10"}

# ---------------------------------------------------------------------------
# 1. General Infrastructure
# ---------------------------------------------------------------------------
with Diagram(
    "oas — General Infrastructure",
    filename=f"{OUT}/01-general-infrastructure",
    outformat="png",
    direction="TB",
    graph_attr=GRAPH_ATTR,
    node_attr=NODE_ATTR,
    edge_attr=EDGE_ATTR,
    show=False,
):
    users = User("End users\n(browser)")
    admins = User("Administrators")
    workspaces = User("LZ Workspaces\nSQL Developer")
    internet = InternetAlt1("Internet\n(yum / SSM endpoints)")

    with Cluster("oas account · eu-west-2 (Modernisation Platform shared VPC)"):
        r53 = Route53("Route53\noas.laa-<env>...")
        acm = ACM("ACM cert\n*.laa-<env>...")
        waf = WAF("WAFv2 Web ACL\nCRS + SQLi + KnownBad\n(COUNT mode)")
        ssm = SystemsManager("SSM\nSession Manager")

        with Cluster("Public subnet"):
            bastion = EC2("Bastion host\n(bastion-linux module)")

        with Cluster("Private subnet A"):
            alb = ElbApplicationLoadBalancer(
                "ALB oas-lb\ninternal\n:80/443/9500-9503"
            )
            ec2 = EC2("EC2 r5a.large\nOracle Linux 8.10\nWebLogic + Analytics")
            ebs1 = EBS("EBS 300GB gp3\n/oracle/software")
            ebs2 = EBS("EBS 300GB gp3\n/stage")

        with Cluster("Data subnets A/B/C"):
            rds = RDSOracleInstance("RDS Oracle 19c EE\ndb.t3.medium")

        sm = SecretsManager(
            "Secrets Manager\nSSH key · DB password\nSlack webhook"
        )
        kms = KMS("KMS\nEBS / RDS keys")
        s3logs = S3("S3\nALB access logs")
        s3waf = S3("S3\nWAF logs")
        s3files = S3("S3\nfiles bucket")
        lamrot = Lambda("Lambda\nrotate-db-master\n-password")
        lamslack = Lambda("Lambda\nsecurity-alerts\n-to-slack")
        sns = SNS("SNS\noas-security-alerts")

    slack = InternetAlt1("Slack\nwebhook")

    users >> Edge(label="HTTPS 443") >> alb
    r53 >> Edge(style="dashed", label="DNS alias") >> alb
    acm >> Edge(style="dashed", label="TLS cert") >> alb
    waf >> Edge(label="WebACL association") >> alb
    alb >> Edge(label="9500-9503") >> ec2
    alb >> Edge(style="dashed", label="access logs") >> s3logs
    waf >> Edge(style="dashed", label="logs") >> s3waf

    admins >> Edge(label="SSH 22") >> bastion >> Edge(label="SSH 22") >> ec2
    admins >> Edge(label="SSM session") >> ssm >> Edge(style="dashed") >> ec2
    bastion >> Edge(style="dashed", label="1521") >> rds

    ec2 >> Edge(label="Oracle 1521") >> rds
    workspaces >> Edge(label="SQL Developer 1521", style="dashed") >> rds
    ec2 >> ebs1
    ec2 >> ebs2
    ec2 >> Edge(style="dashed", label="secrets") >> sm
    ec2 >> Edge(style="dashed") >> s3files
    ec2 >> Edge(style="dashed", label="yum / SSM") >> internet
    rds >> Edge(style="dashed", label="encryption") >> kms

    lamrot >> Edge(label="ModifyDBInstance") >> rds
    lamrot >> Edge(style="dashed", label="rotate") >> sm
    sns >> lamslack >> Edge(label="webhook") >> slack

print("done")
