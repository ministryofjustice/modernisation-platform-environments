import os
import json
import datetime
import logging


# Enable debug logging if DEBUG_LOGGING is set
if os.environ.get('DEBUG_LOGGING', '').lower() in ('1', 'true', 'yes'):
    logging.basicConfig(level=logging.DEBUG)
else:
    logging.basicConfig(level=logging.INFO)
    
def lambda_handler(event, context):
    """
    This Lambda calculates a safe restart time:
    - use the configured restart day/time (by default)
    - avoid scheduling the restart AFTER AWS’s forced restart event time (e.g. aws event coming at 15:00)
    - Ensures restarts always happen out-of-hours (e.g. 22:00)
    """

    # Extract what time the eventbridge event arrived
    # usually the event notification time matches the aws forced restart time (and forced restart day is +7 days)
    event_notification_time_str = event.get('time', None)

    # If the event time is not available, return an error
    if event_notification_time_str is None:
        return {
            'statusCode': 400,
            'error': 'Missing event time in the EventBridge event.'
        }

    # Parse the event time into a datetime object (example"2023-08-16T23:18:51Z")
    event_notification_time = datetime.datetime.strptime(event_notification_time_str, '%Y-%m-%dT%H:%M:%SZ')
    logging.debug("AWS Notification (usually this matches aws restart time) time from event:", event_notification_time)

    # Now get the AWS restart datetime (e.g. “November 26 15:00")
    # usually it will be +7 days from the event notification time but is also in the json
    aws_forced_restart_datetime = event_notification_time + datetime.timedelta(days=7)
    logging.debug(f"AWS forced restart day and time: {aws_forced_restart_datetime}")

    # Get the configured desired restart time (as a string) set by users and in the payload
    configured_restart_time_str = event.get('restart_time', '22:00') # default is set to 10 PM
    configured_restart_day = event.get('restart_day_of_the_week', 'WEDNESDAY').upper()

    # get the configured desired restart time of day
    configured_restart_time_of_day = datetime.datetime.strptime(configured_restart_time_str, '%H:%M').time()

    logging.debug("Configured Restart time of day:", configured_restart_time_of_day)
    logging.debug("Configured Restart week day:", configured_restart_day)

    # get the next occurrence of the desired day of the week but after the current day
    days_of_week = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY']
    # extract current day details from the time we got the event which should be today
    today_day_name = days_of_week[event_notification_time.weekday()]
    today_date = event_notification_time.date()

    logging.debug(f"Today is {today_day_name}, and AWS forced restart: {aws_forced_restart_datetime}")
    logging.debug(f"Configured restart day/time: {configured_restart_day} {configured_restart_time_of_day}")

    # SCENARIO 1 - Today is the same as the configured restart day
    # If today is the restart day AND AWS’s forced restart occurs earlier on the same configured restart day,
    # then today is invalid, so go forward + 1 day and restart at 22:00 hours
    if today_day_name == configured_restart_day:
        logging.debug("Today IS the configured restart day")
        
        # candidate restart time today
        candidate_restart_day_and_time = datetime.datetime.combine(today_date, configured_restart_time_of_day)

        # If today’s restart time (22:00) is AFTER AWS event time (15:00), this is not good as AWS can kick off ECS retiring
        # anytime after its forced restart time so we move it to next day
        if candidate_restart_day_and_time > aws_forced_restart_datetime:
            logging.debug("Today is restart day but restart time is after AWS forced time → cannot use today, moving 1 day ahead..")
            candidate_restart_day_and_time = candidate_restart_day_and_time + datetime.timedelta(days=1)
        
        #Final valid restart day and time
        logging.debug(f"Final restart day and time = {candidate_restart_day_and_time}")

        # Return the new calculated timestamp to restart
        return {
            'statusCode': 200,
            'timestamp': candidate_restart_day_and_time.isoformat() + 'Z'  # Assuming UTC
        }

    # SCENARIO 2 - Today is not the configured restart day
    logging.debug("Today is NOT the configured restart day")
    # Calculate the next occurrence of the configured restart day
    today_weekday_index = days_of_week.index(today_day_name)
    target_weekday_index = days_of_week.index(configured_restart_day)
    # Days until configured weekday in the SAME week (0–6) or next
    days_until_configured_day = (target_weekday_index - today_weekday_index) % 7
    if days_until_configured_day == 0:
        days_until_configured_day = 7

    candidate_restart_date = today_date + datetime.timedelta(days=days_until_configured_day)
    candidate_restart_day_and_time = datetime.datetime.combine(candidate_restart_date, configured_restart_time_of_day)

    #Final valid restart day and time
    logging.debug(f"Final restart day and time = {candidate_restart_day_and_time}")

    # Return the calculated timestamp
    return {
        'statusCode': 200,
        'timestamp': candidate_restart_day_and_time.isoformat() + 'Z'  # Assuming UTC
    }
