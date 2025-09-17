# Service Runbook

_If you have any questions surrounding this page please post in the `#laa-appops` channel._

## Mandatory Information

### **Last review date:**

08/07/2025 - Andy Welsh. Service Redeployment

### **Description:**

CCMS-SOA (Service Oriented Architecture) acts as the service bus for CCMS. The application runs in an AWS ECS Cluster using manually configured, ECS-Optimised, EC2 Instances as it's underlying compute. These instances are provisioned via an Auto Scaling Group and deployed using a Launch Template and associated User Data boot script.

SOA operates in a client-server arrangement with a single _Admin Server_ on it's own EC2 instance, running a single container and a variable number of _Enterprise Management Servers_, often referred to as simply _Managed Servers_. These managed servers may run across a variable amount of individual EC2 instances and a variable amount of containers, spread across these instances.

For an architecture diagram, see the [LLD in the central architecture diagram repo](https://github.com/ministryofjustice/laa-architectural-diagrams/blob/main/docs/diagrams/lld/ccms/ccms-soa.png).

### **Databases:**

The application is backed by two RDS (Oracle) databases:

**SOA-DB:**

This is a custom DB used by Document Service SOA composite for caching documents before making calls to CCMS-EBS. The reason behind this is SOA is configured to retry in the event of any error while invoking EBS PL/SQL stored procedure to insert documents. Typical usage is when PUI and Apply applications submit documents to CCMS-EBS via SOA.

**TDS-DB:**

This database is essential for the SOA system to inject documents that are ultimately transmitted to NEC (Northgate).
Previously, the database was tightly coupled with the SOA infrastructure.
However, it has since been decoupled and is now managed under the ownership of the EDRMS application.

Given that EDRMS is the primary stakeholder of this database, EDRMS should ideally be deployed first.
The database should be initialized using the scripts provided in the EDRMS environment.
Additionally, the necessary configuration details—such as the JDBC URL, username, and password—should be stored in a secret, which can then be referenced by the SOA WebLogic cluster through its datasource binding.

### **Storage:**

Application state is held on an EFS storage volume, this is mounted to the ECS clusters EC2 Instances as part of their boot process and exposed to the running containers.

### **Service URLs:**

- **Administration Consle**: `https://ccms-soa-admin.laa-ENVIRONMENT.modernisation-platform.service.justice.gov.uk/console`
- **EM (Enterprise Manager)**: `https://ccms-soa-admin.laa-ENVIRONMENT.modernisation-platform.service.justice.gov.uk/em`
- **Composite Integrations**: `https://ccms-soa-managed.laa-ENVIRONMENT.modernisation-platform.service.justice.gov.uk`

ENVIRONMENT values:
- development
- test
- preproduction
- production

### **Incident response hours:**

Best Endeavours

### **Incident contact details:**

<laa-role-sre@digital.justice.gov.uk>

### **Service team contact:**

<laa-role-sre@digital.justice.gov.uk>

### **Hosting environment:**

Modernisation Platform

### **Automatic alerts:**

Alerting will be sent to the following slack channels:

- `#laa-alerts-ccms-soa-nonprod`
- `#laa-alerts-ccms-soa-prod`

Depending on environment. Alerts are based on Cloudwatch Metric filters, and are relayed on as Cloudwatch Alarms being tripped, relayed via SNS to Amazon Q (Chatbot).

Alerts include infrastructure level monitoring for compute overconsumption as well as application level issues such unavailable endpoints. Rather than attempt to list all metric filters and alarms in this document (as they will evolve over time), see the configurations in code [here](./logs.tf) for metric filters and [here](./alerting.tf) for alarms.

**NOTE ON MONITORING COMPOSITE ENDPOINTS**

Composite endpoints are individually monitored by SOA by an internal process and the outcomes of their checks relayed on to the same Cloudwatch alerting mechanism described above.

A list of custom endpoints (which includes all composites that need to be managed) is defined in a file named `paths_to_check.txt` at the root of the shared EFS volume for each environment. This file is stored in the `laa-ccms-soa-app` and is loaded on to the EFS filesystem as part of the EC2 boot script for each instance.

If a composite is taken offline, this will result in errors being fired, to remove an endpoint from constant monitoring, simply remove it from the `paths_to_check.txt` file. These changes take effect in real time and do not require a restart of any services, containers or underlying hosts.

### **Impact of an outage:**

SOA is a critical component of CCMS and provides key integrations to several other external services.

Without SOA:

- Case data, client details and invoice details are not transferred from PUI/Apply to EBS. New cases will not flow into EBS for caseworkers to assess.
- The notification service will not function, and providers will not be alerted to changes to cases or certificates being granted, or financial statements (PSOAs) being generated.

In an extended outage:

- FTP services which are managed by SOA will not run, the AppOps SRE team will be unable to load payment files into the BACS software processor or for printing to be carried out by third parties
- Finance teams would be unable to reconcile receipts and payments made, meaning we cannot provide an accurate picture of the LAA’s material position to HMT, NAO or others

### **Consumers of this service:**

- CCMS-EBS (MP)
- CCMS-EDRMS (MP)
- Benefit Checker (CP)
- OIA Hub (CP)
- Assess Service Adapter (CP)
- Payment FTP Lambdas (MP)
- CWA (ECP)

### **Services consumed by this:**

- CCMS-EBS S3 (`laa-ccms-inbound-ENVIRONMENT-mp` and `laa-ccms-outbound-ENVIRONMENT-mp`)

### **Restrictions on access:**

Accessible from a [Shared Services AWS Workspace](https://dsdmoj.atlassian.net/wiki/spaces/aws/pages/4450288123/Self+Workspace+Creation+-+User+Guide) or other services within Mod Platform (MP):

- **Administration Console**: <https://ccms-soa-admin.laa-$ENVIRONMENT.modernisation-platform.service.justice.gov.uk/console>
- **EM (Enterprise Manager)**: <https://ccms-soa-admin.laa-$ENVIRONMENT.modernisation-platform.service.justice.gov.uk/em>

Exposed to other Mod Platform (MP) and Cloud Platform (CP) services. Available from Accessible from a [Shared Services AWS Workspace](https://dsdmoj.atlassian.net/wiki/spaces/aws/pages/4450288123/Self+Workspace+Creation+-+User+Guide) (for the purposes of integration testing):
- **Composite Integrations** (<https://ccms-soa-admin.laa-$ENVIRONMENT.modernisation-platform.service.justice.gov.uk>)

See the below table for which Workspace should be used for which Workspace should be used to access which environment:

| Environment   | Workspace |
|---------------|-----------|
| Development   | Non-Prod  |
| Test          | Prod      |
| Preproduction | Prod      |
| Production    | Prod      |

### **How to resolve specific issues:**

See [here](docs/KNOWN_ISSUES.md) for known issues and how to tackle them.

### **Service Restoration and New Environment Creation:**

See [here](docs/SERVICE_RESTORE.md) for an extensive breakdown of how to create a new environment or how to restore SOA in the event of disaster recovery.
