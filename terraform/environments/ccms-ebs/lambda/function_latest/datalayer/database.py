import oracledb
from config.database_config import get_database_connection_settings
from config.oracle_client_config import get_database_client_settings


class OracleClientInit:
    """Singleton class to perform init_oracle_client once only"""
    __instance = None

    def __new__(cls):
        if cls.__instance is None:
            cls.__instance = super(OracleClientInit, cls).__new__(cls)
            cls.initiate_oracle_client()

    @classmethod
    def initiate_oracle_client(cls):
        database_client_settings = get_database_client_settings()
        if database_client_settings.system_os == "Linux":
            oracledb.init_oracle_client()
        else:
            oracledb.init_oracle_client(lib_dir=database_client_settings.oracle_client_directory)


class DbConnection:
    def __init__(self):
        OracleClientInit()
        self.connection = None

    def connect(self):
        if not self.connection:
            parameters = get_database_connection_settings()
            self.connection = oracledb.connect(**parameters.dict())

    def run_query(self, sql, params=None):
        rows = []
        error = None
        try:
            self.connect()
            with self.connection.cursor() as cursor:
                cursor.execute(sql, params)
                rows = cursor.fetchall()
        except oracledb.DatabaseError as e:
            error = str(e)
        return rows, error

    def insert_row(self, sql, params=None):
        error = None
        try:
            self.connect()
            with self.connection.cursor() as cursor:
                cursor.execute(sql, params)
                rowcount = cursor.rowcount
        except oracledb.DatabaseError as e:
            error = str(e)
            rowcount = 0
        return rowcount, error

    def disconnect(self):
        if self.connection is not None:
            self.connection.close()


def get_database_hostname():
    conn = DbConnection()
    rows, error = conn.run_query("select utl_inaddr.get_host_name from dual")
    conn.disconnect()
    if not error:
        return rows[0][0], None
    else:
        return None, error
