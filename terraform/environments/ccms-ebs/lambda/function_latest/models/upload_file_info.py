from pydantic import BaseModel


class FileInfo(BaseModel):
    # filename and size - retrieved from file list
    filename: str
    size: int
    # content_type and content_length - retrieved from individual file details
    content_type: str
    content_length: int
