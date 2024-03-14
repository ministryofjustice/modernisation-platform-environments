import boto3

client = boto3.client('cloudwatch')

file1 = open("alarms.txt", "r")
enable_alarm = file1.readlines()
enable_alarm = [line.rstrip() for line in enable_alarm]
print(enable_alarm)
response = client.enable_alarm_actions(AlarmNames=enable_alarm)