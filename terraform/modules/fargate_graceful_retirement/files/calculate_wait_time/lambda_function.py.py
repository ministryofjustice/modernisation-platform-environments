import json
import datetime

def lambda_handler(event, context):
    # Extract current event time
    current_time_str = event.get('time', '')

    # Parse the event time into a datetime object
    event_time = datetime.datetime.strptime(current_time_str, '%Y-%m-%dT%H:%M:%SZ')

    # Define the desired restart time (as a string, e.g., "14:30:00" for 2:30 PM)
    restart_time_str = event.get('restart_time', '14:30:00')

    # Combine the event date with the desired time
    restart_time = datetime.datetime.combine(event_time.date(), datetime.time.fromisoformat(restart_time_str))

    # Return the calculated timestamp
    return {
        'statusCode': 200,
        'timestamp': restart_time.isoformat() + 'Z'  # Add 'Z' for UTC time
    }
