from collections.abc import Mapping
from typing import Any


class InvalidMessage(ValueError):
    """An event or dispatch configuration is not authorised for this writer."""


class AwsResponseError(RuntimeError):
    def __init__(self, message: str, fields: Mapping[str, Any]):
        super().__init__(message)
        self.fields = dict(fields)