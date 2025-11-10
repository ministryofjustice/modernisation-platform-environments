from pydantic import BaseSettings
from functools import lru_cache
from datalayer.database_client_config import (get_platform,
                                              set_ld_library_path)


class DatabaseClientSettings(BaseSettings):
    system_os = get_platform()
    oracle_client_directories = {
        "Darwin": "instantclient/instantclient_12_2_macos",
        "Linux": "instantclient/instantclient_12_2_linux",
        "Windows": r"instantclient\instantclient_12_2_windows"
    }

    @property
    def oracle_client_directory(self) -> str:
        return self.oracle_client_directories.get(self.system_os, None)

    @property
    def ld_library_path_set(self) -> bool:
        return set_ld_library_path(self.system_os, self.oracle_client_directory())


@lru_cache()
def get_database_client_settings():
    return DatabaseClientSettings()
