# CCMS-SOA - Known Issues

## A Newly Launched Managed Server is not registered in Weblogic

In the event that a new managed server has booted correctly (and is showing a stable healthcheck on it's EC2 Loadbalancer) but is not properly registering in Weblogic as shown below, this is likley an issue with caching in the Admin server:

![Registration Error](reg-error.png)

To resolve:

- Scale down the Admin Server tasks to `0` in the ECS console.
- Start a new SSM session on the Admin Server EC2 host.
- Execute `sudo docker container ls` and wait for the admin container to stop running
- Once the container has stopped run:

```bash
sudo su ec2-user
cd ~/efs/domains/soainfra/servers
rm -r domain_bak
rm -r AdminServer/cache
rm -r AdminServer/logs
rm -r AdminServer/tmp
```

Exit the terminal and scale the Admin Server back up to `1` instance. Once booted, all Managed Servers should be registered in Weblogic.

## ERROR: RCU Loading Failed. Check the RCU logs

If during the initial starting of an Admin Server in a fresh environment the Admin Server refuses to start and throws an error along the lines of:

```bash
ERROR: RCU Loading Failed. Check the RCU logs
```

This is likely due to one of two reasons.

1. A compatibility issue between Oracle and RDS. The Oracle [RCU](https://docs.oracle.com/cd/E21764_01/doc.1111/e14259/overview.htm) is configured to execute as part of the startup process of the SOA Admin Server and pre-configures the database ready for use. This will happen by default on a fresh database and can be resolved by a DBA executing the below statement:

```bash
EXECUTE rdsadmin.rdsadmin_util.grant_sys_object( p_obj_name => 'DBA_TABLESPACE_USAGE_METRICS', p_grantee => 'SOAPDB', p_privilege => 'SELECT', p_grant_option => true);
```

2. The build guide was not properly followed and one of the components that the RCU creates was manually created. If the RCU finds that an object it is attempting to create already exists it will exit and cause the application to crash loop. If this has been done, it is probably faster to delete the entire database instance **AND** EFS volume and start again (assuming you are in the early stages of a fresh build).
