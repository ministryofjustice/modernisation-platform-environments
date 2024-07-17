import os
import pyodbc

def lambda_handler(event, context):
    # Fetching environment variables
    db_url = os.getenv("DB_URL")
    user_name = os.getenv("USER_NAME")
    password = os.getenv("PASSWORD")
    new_db_name = os.getenv("NEW_DB_NAME")
    new_user_name = os.getenv("NEW_USER_NAME")
    new_password = os.getenv("NEW_PASSWORD")
    app_folder = os.getenv("APP_FOLDER")

    print(f"exported ENV values are 1: {db_url}")

    print("Creating initial database....")
    print(f"DB_URL is <{db_url}>")

    # Establishing initial connection (CREATE DATABASE statement not allowed within multi-statement transaction)
    conn = pyodbc.connect(
        f"DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={db_url};UID={user_name};PWD={password}",
        autocommit=True
    )
    cursor = conn.cursor()
    cursor.execute(f"CREATE DATABASE {new_db_name}")
    cursor.close()
    conn.close()

    # Re-establishing connection to execute remaining commands
    conn = pyodbc.connect(
        f"DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={db_url};UID={user_name};PWD={password}"
    )
    cursor = conn.cursor()

    # Executing SQL commands
    commands = [
        f"CREATE LOGIN [{new_user_name}] WITH PASSWORD = '{new_password}'",
        f"CREATE USER [{new_user_name}] FOR LOGIN [{new_user_name}]",
        f"USE [{new_db_name}]; EXEC sp_addrolemember N'db_owner', N'{new_user_name}'"
    ]

    for command in commands:
        cursor.execute(command)
        conn.commit()

    # Executing SQL script from file
    script_path = f"/{app_folder}/sp_migration.sql"
    with open(script_path, 'r') as file:
        script = file.read()
        for statement in script.split(';'):
            if statement.strip():
                cursor.execute(statement)
                conn.commit()

    # Closing the connection
    cursor.close()
    conn.close()

    return {
        'statusCode': 200,
        'body': 'Database setup completed successfully'
    }