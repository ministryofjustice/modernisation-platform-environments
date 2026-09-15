# Regenerates the PNGs in ./images from the current architecture.
# Requires: brew install graphviz && pip install diagrams
# Run:      python3 generate.py
import os
from diagrams import Diagram, Cluster, Edge
from diagrams.aws.network import (
    VPC, PublicSubnet, PrivateSubnet, InternetGateway, NATGateway,
    NetworkFirewall, TransitGateway, ElbApplicationLoadBalancer,
    ElbNetworkLoadBalancer, ClientVpn, Endpoint,
)
from diagrams.aws.security import ManagedMicrosoftAd, SecretsManager, KMS
from diagrams.aws.compute import ECS, EC2, Lambda, ECR
from diagrams.aws.database import RDSMysqlInstance
from diagrams.aws.enduser import Workspaces
from diagrams.aws.engagement import SES
from diagrams.aws.general import User, InternetAlt1, OfficeBuilding

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
    "laa-new-workspaces — General Infrastructure",
    filename=f"{OUT}/01-general-infrastructure",
    outformat="png",
    direction="TB",
    graph_attr=GRAPH_ATTR,
    node_attr=NODE_ATTR,
    edge_attr=EDGE_ATTR,
    show=False,
):
    client = User("WorkSpaces Client\nWindows / macOS / Web")
    vpn = ClientVpn("Global Protect\nVPN Gateway")
    internet = InternetAlt1("Internet")
    moj = OfficeBuilding("MoJ Shared TGW\nLAA Network\n10.0.0.0/8")

    with Cluster("laa-new-workspaces account · eu-west-2"):
        ecr = ECR("ECR\nlinotp3 / freeradius")
        sm = SecretsManager("Secrets Manager")
        kms = KMS("KMS\nebs key")
        ses = SES("SES")

        with Cluster("Automation"):
            lam1 = Lambda("user-lifecycle")
            lam2 = Lambda("user-creation")
            lam1 >> lam2

        with Cluster("VPC 10.26.130.0/23"):
            with Cluster("Public Subnets · 2 AZs"):
                alb = ElbApplicationLoadBalancer("ALB radmfa\nHTTPS:443")

            with Cluster("Private Subnets · 2 AZs"):
                ad = ManagedMicrosoftAd("Microsoft AD\nlaa-workspaces.local")
                wsdir = Workspaces("WorkSpaces\nDirectory")
                nlb = ElbNetworkLoadBalancer("Internal NLB\nUDP:1812")
                with Cluster("ECS Fargate Task"):
                    ecs = ECS("linotp:5000 +\nfreeradius:1812/1813")
                rds = RDSMysqlInstance("RDS MySQL 8.0\nlinotp3")
                ec2w = EC2("Windows EC2\ndomain-joined")
                vpce = Endpoint("VPC Endpoints\nSSM/SecretsMgr/S3")

            with Cluster("NAT Subnet"):
                nat = NATGateway("NAT Gateway")

            with Cluster("Firewall Subnets"):
                fw = NetworkFirewall("Network Firewall\nFQDN allow-list")

            igw = InternetGateway("Internet\nGateway")

        tgw = TransitGateway("Transit Gateway\nattachment")

    client >> vpn
    vpn >> Edge(label="WSP/PCoIP") >> wsdir
    vpn >> Edge(label="HTTPS 443") >> alb
    alb >> ecs
    wsdir >> Edge(color="gray") << ad
    ad >> Edge(label="RADIUS 1812") >> nlb >> ecs
    ecs >> rds
    ecs >> Edge(style="dashed", label="secrets") >> sm
    ecr >> Edge(style="dashed", label="image pull") >> ecs

    lam1 >> Edge(label="reads") >> sm
    lam2 >> Edge(label="SSM Send-Command") >> ec2w
    ec2w >> Edge(label="LDAP/PowerShell") >> ad
    lam2 >> wsdir
    lam2 >> ses
    lam2 >> Edge(style="dashed", label="decrypt") >> kms

    fw >> nat >> igw >> internet
    tgw >> moj

# ---------------------------------------------------------------------------
# 2a. Data Flow - Provisioning & Deprovisioning
# ---------------------------------------------------------------------------
with Diagram(
    "laa-new-workspaces — Data Flow: Provisioning",
    filename=f"{OUT}/02a-data-flow-provisioning",
    outformat="png",
    direction="LR",
    graph_attr=GRAPH_ATTR,
    node_attr=NODE_ATTR,
    edge_attr=EDGE_ATTR,
    show=False,
):
    ops = User("Ops engineer")
    sec = SecretsManager("user_list")
    lam1 = Lambda("user-lifecycle")
    lam2 = Lambda("user-creation")
    ec2w = EC2("Windows EC2\ndomain-joined")
    ad = ManagedMicrosoftAd("Microsoft AD")
    ws = Workspaces("WorkSpace")
    ses = SES("SES")
    newuser = User("New user")

    ops >> Edge(label="1. edits") >> sec
    sec >> Edge(label="2. version change") >> lam1
    lam1 >> Edge(label="3a. new user") >> lam2
    lam2 >> Edge(label="4. SSM Send-Command") >> ec2w
    ec2w >> Edge(label="5. New-ADUser (RSAT)") >> ad
    lam2 >> Edge(label="6. CreateWorkspaces") >> ws
    lam2 >> Edge(label="7. welcome email") >> ses
    ses >> Edge(label="8. enrollment link") >> newuser
    lam1 >> Edge(label="3b. user removed:\nTerminate + DeleteUser", style="dashed", color="firebrick") >> ws
    lam1 >> Edge(style="dashed", color="firebrick") >> ad

# ---------------------------------------------------------------------------
# 2b. Data Flow - Outbound Web Filtering
# ---------------------------------------------------------------------------
with Diagram(
    "laa-new-workspaces — Data Flow: Outbound Filtering",
    filename=f"{OUT}/02b-data-flow-egress",
    outformat="png",
    direction="LR",
    graph_attr=GRAPH_ATTR,
    node_attr=NODE_ATTR,
    edge_attr=EDGE_ATTR,
    show=False,
):
    ws = Workspaces("WorkSpace /\nECS task")
    fw = NetworkFirewall("Network Firewall\nstateful allow-list")
    nat = NATGateway("NAT Gateway")
    igw = InternetGateway("Internet Gateway")
    net = InternetAlt1("Internet")

    ws >> Edge(label="0.0.0.0/0") >> fw
    fw >> Edge(label="allowed:\n.microsoft.com\n.windowsupdate.com\n.office.com") >> nat >> igw >> net

# ---------------------------------------------------------------------------
# 3a. Authentication - WorkSpaces login + MFA
# ---------------------------------------------------------------------------
with Diagram(
    "laa-new-workspaces — Authentication: Login + MFA",
    filename=f"{OUT}/03a-authentication-login-mfa",
    outformat="png",
    direction="LR",
    graph_attr=GRAPH_ATTR,
    node_attr=NODE_ATTR,
    edge_attr=EDGE_ATTR,
    show=False,
):
    user = User("User")
    wsdir = Workspaces("WorkSpaces\nDirectory")
    ad = ManagedMicrosoftAd("Microsoft AD")
    nlb = ElbNetworkLoadBalancer("Internal NLB\nUDP:1812")
    with Cluster("ECS Fargate Task"):
        rad = ECS("FreeRADIUS")
        lotp = ECS("LinOTP :5000")
    rds = RDSMysqlInstance("RDS MySQL")

    user >> Edge(label="1. AD username + password") >> wsdir
    wsdir >> Edge(label="2. bind/validate") >> ad
    ad >> Edge(label="3. RADIUS Access-Request\n(PAP, shared secret)") >> nlb
    nlb >> Edge(label="4. forward UDP:1812") >> rad
    rad >> Edge(label="5. HTTP /validate/simplecheck") >> lotp
    lotp >> Edge(label="6. LDAP lookup\n(ad-resolver)") >> ad
    lotp >> Edge(label="7. check OTP") >> rds
    lotp >> Edge(label="8. accept/reject", color="darkgreen") >> rad
    rad >> Edge(label="9. Access-Accept/Reject", color="darkgreen") >> nlb
    nlb >> Edge(label="10. result", color="darkgreen") >> ad
    ad >> Edge(label="11. MFA result", color="darkgreen") >> wsdir
    wsdir >> Edge(label="12. session granted/denied", color="darkgreen") >> user

# ---------------------------------------------------------------------------
# 3b. Authentication - Self-service enrollment
# ---------------------------------------------------------------------------
with Diagram(
    "laa-new-workspaces — Authentication: Self-Service Enrollment",
    filename=f"{OUT}/03b-authentication-enrollment",
    outformat="png",
    direction="LR",
    graph_attr=GRAPH_ATTR,
    node_attr=NODE_ATTR,
    edge_attr=EDGE_ATTR,
    show=False,
):
    user = User("User\n(browser)")
    alb = ElbApplicationLoadBalancer("ALB radmfa\nHTTPS:443")
    lotp = ECS("LinOTP portal\n:5000")
    ad = ManagedMicrosoftAd("Microsoft AD")
    rds = RDSMysqlInstance("RDS MySQL")

    user >> Edge(label="1. HTTPS (VPN CIDR only)") >> alb
    alb >> Edge(label="2. forward :5000") >> lotp
    lotp >> Edge(label="3. LDAP bind\n(ad-resolver)") >> ad
    ad >> Edge(label="4. authenticated", color="darkgreen") >> lotp
    user >> Edge(label="5. enroll MFA token") >> lotp
    lotp >> Edge(label="6. store token seed\n(encrypted)") >> rds

print("done")
