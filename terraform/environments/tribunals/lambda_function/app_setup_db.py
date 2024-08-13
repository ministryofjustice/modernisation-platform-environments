import os
import pyodbc
import re

def lambda_handler(event, context):
    # Fetching environment variables
    db_url = os.getenv("DB_URL")
    user_name = os.getenv("USER_NAME")
    password = os.getenv("PASSWORD")
    new_db_name = os.getenv("NEW_DB_NAME")
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

    # Check if the database already exists
    cursor.execute(f"SELECT name FROM sys.databases WHERE name = '{new_db_name}'")
    database_exists = cursor.fetchone()

    if not database_exists:
        print(f"Creating database [{new_db_name}]...")
        cursor.execute(f"CREATE DATABASE [{new_db_name}]")
    else:
        print(f"Database [{new_db_name}] already exists.")

    cursor.close()
    conn.close()

    # Re-establishing connection to execute remaining commands
    conn = pyodbc.connect(
        f"DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={db_url};UID={user_name};PWD={password}"
    )
    cursor = conn.cursor()

    # Executing SQL script from file
    script_path = f".{app_folder}/sp_migration.sql"
    with open(script_path, 'r') as file:
        script = file.read()
        # Split the script by the full keyword 'GO' (case-insensitive)
        statements = re.split(r'\bGO\b', script, flags=re.IGNORECASE)
        for statement in statements:
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