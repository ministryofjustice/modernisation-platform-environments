import boto3
client = boto3.client('cloudwatch')

response = client.describe_alarms()

for alarm in response['MetricAlarms']:
    status = alarm['ActionsEnabled']
    if status:
        name = alarm['CPU-High-i-029d2b17679dab982','CPU-High-i-00cbccc46d25e77c6']
        disable_alarm = client.disable_alarm_actions(AlarmNames=[name])
        print("Alarm {} is disabled".format(name))
        file1 = open("alarms.txt", "a")
        file1.write(name+"\n")
    else:
        print("No enabled Alarms")