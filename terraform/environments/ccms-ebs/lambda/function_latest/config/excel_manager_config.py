from pydantic import BaseSettings
from functools import lru_cache


class RequiredColumns(BaseSettings):
    column_headers: list[str] = ["LSC Account Number",
                                 "Area of Law",
                                 "Amount £"]


@lru_cache()
def get_required_columns():
    return RequiredColumns()
