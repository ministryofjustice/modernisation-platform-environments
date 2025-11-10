from pydantic import BaseSettings
from functools import lru_cache
# relative import (with dot) needed otherwise tests fail
from .get_secret import get_secret


class DatabaseConnectionSettings(BaseSettings):
    # These attributes have the same names as the parameters
    # used by 3rd party oracledb.connect method to enable it
    # to be called conveniently.
    password: str
    user: str
    host: str
    port: int
    service_name: str


class DatabaseEnvironmentSettings(BaseSettings):
    """These attributes are intended to be automatically set from environment variables
    with matching (case insenstive) names. Note the default True value for is_production
    is overridden by an environment variable of same name if set."""
    s3_bucket_name: str
    is_production: bool = True


@lru_cache()
def get_database_connection_settings():
    secrets = get_secret()
    database_connection_settings = DatabaseConnectionSettings(
        password=secrets.get("DB_PASSWORD"),
        user=secrets.get("DB_USER"),
        host=secrets.get("DB_HOST"),
        port=secrets.get("DB_PORT"),
        service_name=secrets.get("DB_SID")
    )
    return database_connection_settings


@lru_cache()
def get_database_environment_settings():
    return DatabaseEnvironmentSettings()
