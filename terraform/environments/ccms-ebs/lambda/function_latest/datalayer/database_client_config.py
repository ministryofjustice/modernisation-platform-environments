import platform
import os


def get_platform():
    return platform.system()


def set_ld_library_path(system_os, library_path):
    """Set LD_LIBRARY_PATH environment variable when on Linux but not on
    Windows or Mac OS. Return True/False depending on whether set.
    This is required for for oracledb.init_oracle_client call when running
    on Linux because its ld_dir parameter only works on Windows and Mac OS.
    However, note that LD_LIBRARY_PATH value is not sufficient on Ubuntu Linux
    where it is necessary to create a set a .conf file instead/as well.
    """
    was_set = False
    if system_os == "Linux":
        os.environ["LD_LIBRARY_PATH"] = os.path.join(os.getcwd(), library_path)
        was_set = True
    return was_set
