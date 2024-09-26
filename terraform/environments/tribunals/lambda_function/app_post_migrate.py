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
    admin_username = os.getenv("ADMIN_USERNAME")
    admin_password = os.getenv("ADMIN_PASSWORD")
    admin_password_eat = os.getenv("ADMIN_PASSWORD_EAT")

    print(f"exported ENV values are 1: {db_url}")
    print(f"DB_URL is <{db_url}>")

    conn = pyodbc.connect(
        f"DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={db_url};UID={user_name};PWD={password}",
        autocommit=True
    )
    cursor = conn.cursor()
    cursor.execute(f"use [{new_db_name}]")

    # Insert legacy apps admin user into the database
    if (new_db_name == 'eat'):
        cursor.execute("SET IDENTITY_INSERT dbo.ValidUsers ON;")
        cursor.execute(
            "INSERT INTO ValidUsers (id, UserName, Password) VALUES (?, ?, ?);",
            (100, admin_username, admin_password_eat)
        )
        cursor.execute("SET IDENTITY_INSERT dbo.ValidUsers OFF;")
    else:
        cursor.execute("SET IDENTITY_INSERT dbo.Users ON;")
        cursor.execute(
            "INSERT INTO Users (UserID, Username, Password, Firstname, Lastname) VALUES (?, ?, ?, ?, ?);",
            (100, admin_username, admin_password, 'DTS Legacy Apps', 'Team Login')
        )
        cursor.execute("SET IDENTITY_INSERT dbo.Users OFF;")

    # Closing the connection
    cursor.close()
    conn.close()

    return {
        'statusCode': 200,
        'body': 'Database post migration script completed successfully'
    }