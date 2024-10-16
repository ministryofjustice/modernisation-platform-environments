import json
import datetime
def lambda_handler(event, context):
    # Extract current event time
    current_time_str = event.get('time', None)

    # If the event time is not available, return an error
    if current_time_str is None:
        return {
            'statusCode': 400,
            'error': 'Start time not available'
        }

    # Parse the event time into a datetime object (example"2023-08-16T23:18:51Z")
    time = datetime.datetime.strptime(current_time_str, '%Y-%m-%dT%H:%M:%SZ')

    # Define the desired restart time (as a string)
    restart_time_str = event.get('restart_time', '22:00')
    restart_day_of_the_week = event.get('restart_day_of_week', 'WEDNESDAY')

    # get the next occurrence of the desired day of the week but after the current day
    days_of_week = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY']
    current_day_of_the_week = days_of_week[time.weekday()]

    if current_day_of_the_week == restart_day_of_the_week:
        days_until_restart = 7
    else:
        # get the number of days until the next desired day of the week
        days_until_restart = (days_of_week.index(restart_day_of_the_week) - days_of_week.index(current_day_of_the_week)) % 7

    # get the desired restart time as a datetime object
    restart_time = datetime.datetime.strptime(restart_time_str, '%H:%M')

    # add the number of days until the next desired day of the week
    restart_time = datetime.datetime.combine(time.date(), restart_time.time())
    restart_time += datetime.timedelta(days=days_until_restart)

    # Return the calculated timestamp
    return {
        'statusCode': 200,
        'timestamp': restart_time.isoformat() + 'Z'  # Assuming UTC
    }
