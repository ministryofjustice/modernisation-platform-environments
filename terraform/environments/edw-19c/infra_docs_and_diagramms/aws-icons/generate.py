# Generates the General Infrastructure PNG in ./images from the current architecture.
# Only the general-infrastructure diagram uses AWS Architecture Icons — the data flow
# diagram is Mermaid, written directly in 02-data-flow.md.
# Requires: brew install graphviz && pip install diagrams
# Run:      python3 generate.py
import os
from diagrams import Diagram, Cluster, Edge
from diagrams.aws.database import RDSOracleInstance
from diagrams.aws.security import SecretsManager, KMS, IAM
from diagrams.aws.storage import S3
from diagrams.aws.management import Cloudwatch
from diagrams.aws.general import User, Client

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
    "edw-19c — General Infrastructure",
    filename=f"{OUT}/01-general-infrastructure",
    outformat="png",
    direction="TB",
    graph_attr=GRAPH_ATTR,
    node_attr=NODE_ATTR,
    edge_attr=EDGE_ATTR,
    show=False,
):
    workspaces = User("LZ Workspaces\nSQL Developer")
    snapshot_src = Client("Snapshot source\naccount 758955050340")
    replication_src = Client("Replication source\naccount 258180561819\n(edw-upgrade)")

    with Cluster("edw-19c account · eu-west-2 (Modernisation Platform shared VPC) · preproduction only"):
        with Cluster("Data subnets A/B/C"):
            rds = RDSOracleInstance(
                "RDS Oracle 19c EE\ndb.m6i.2xlarge\n3000GB gp3, 12000 IOPS"
            )

        iam = IAM("IAM Role\nrds-s3-access-role\n(S3_INTEGRATION)")
        s3 = S3("S3\nedw-19c-preprod\n-replica-bucket")
        sm = SecretsManager("Secrets Manager\nedw-19c/app/\ndb-master-password")
        kms = KMS("KMS\nRDS shared key")
        cw = Cloudwatch("CloudWatch Logs\nalert/audit/listener\noemagent/trace")

    workspaces >> Edge(label="SQL Developer 1521\n(troubleshooting only)") >> rds
    rds >> Edge(label="assume role") >> iam
    iam >> Edge(label="Data Pump\nexport/import") >> s3
    replication_src >> Edge(label="s3:ReplicateObject\n(cross-account, versioned)", style="dashed") >> s3
    snapshot_src >> Edge(label="restore from snapshot\n(one-time)", style="dashed") >> rds
    rds >> Edge(style="dashed", label="master password") >> sm
    rds >> Edge(style="dashed", label="encryption") >> kms
    rds >> Edge(style="dashed", label="log exports") >> cw

print("done")
