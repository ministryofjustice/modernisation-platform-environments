import os
import subprocess

def handler(event, context):
    db_url = os.environ['DB_URL']
    user_name = os.environ['USER_NAME']
    password = os.environ['PASSWORD']
    new_db_name = os.environ['NEW_DB_NAME']
    new_user_name = os.environ['NEW_USER_NAME']
    new_password = os.environ['NEW_PASSWORD']
    app_folder = os.environ['APP_FOLDER']

    # Run your setup script
    subprocess.run(["chmod", "+x", "./setup-mssql.sh"])
    subprocess.run(["./setup-mssql.sh"], env={
        "DB_URL": db_url,
        "USER_NAME": user_name,
        "PASSWORD": password,
        "NEW_DB_NAME": new_db_name,
        "NEW_USER_NAME": new_user_name,
        "NEW_PASSWORD": new_password,
        "APP_FOLDER": app_folder
    })

    return {
        'statusCode': 200,
        'body': 'Database setup completed successfully'
    }