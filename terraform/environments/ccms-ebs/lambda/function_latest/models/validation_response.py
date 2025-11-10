from pydantic import BaseModel


class ValidationResponse(BaseModel):
    status_code: int
    message: list[str]
