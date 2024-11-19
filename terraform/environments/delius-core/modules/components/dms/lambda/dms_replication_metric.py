import boto3
import json
import logging
import re

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):

    cloudwatch = boto3.client('cloudwatch')
    for record in event['Records']:

        message = json.loads(record['Sns']['Message'])
        logger.info("SNS Message: %s",message)

        event_message = message.get("Event Message")
        event_source  = message.get("Event Source")
        source_id     = message.get("SourceId")

        dms_event_id  = re.search(r"#(DMS-EVENT-\d+) $",message.get("Event ID"))

        # DMS Event IDs are documented at https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Events.html
        #
        # Those relevant for this metric are:
        #
        # Running Replication:
        #  DMS-EVENT-0069: The replication task has started.
        #  DMS-EVENT-0081: A reload of table details has been requested.
        #  DMS-EVENT-0093: Reading resumed.
        running_replication = ["DMS-EVENT-0069","DMS-EVENT-0081","DMS-EVENT-0093"]
        #
        # Stopped Replication:
        #  DMS-EVENT-0079: The replication task has stopped.
        #  DMS-EVENT-0091: Reading paused, swap files limit reached.
        #  DMS-EVENT-0092: Reading paused, disk usage limit reached.
        #  DMS-EVENT-0078: A replication task has failed.
        stopped_replication = ["DMS-EVENT-0079","DMS-EVENT-0091","DMS-EVENT-0092","DMS-EVENT-0078"]

        if dms_event_id.group(1) in running_replication:
            logger.info("TASK START: " + event_source + " task " + source_id + " started")
            cloudwatch.put_metric_data(
                Namespace='CustomDMSMetrics',
                MetricData=[
                    {
                        'MetricName': 'DMSReplicationStopped',
                        'Dimensions': [
                            {'Name': 'SourceId',    'Value': source_id}
                        ],
                        'Value': 0,  # Reset Below Trigger threshold (Task Started)
                        'Unit': 'Count'
                    }
                ]
            )
        elif dms_event_id.group(1) in stopped_replication:
            logger.info("TASK STOPPED: " + event_source + " task " + source_id + " stopped")
            cloudwatch.put_metric_data(
                Namespace='CustomDMSMetrics',
                MetricData=[
                    {
                        'MetricName': 'DMSReplicationStopped',
                        'Dimensions': [
                            {'Name': 'SourceId',    'Value': source_id}
                        ],
                        'Value': 1,  # Trigger threshold (Task Failed)
                        'Unit': 'Count'
                    }
                ]
            )