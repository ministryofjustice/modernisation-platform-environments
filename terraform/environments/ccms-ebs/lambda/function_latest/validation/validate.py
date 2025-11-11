import logging
from models.upload_file_info import FileInfo
from models.validation_response import ValidationResponse


logger = logging.getLogger(__name__)


def validate_request(file_info: FileInfo):
    messages = []
    status_code = None
    validator_sequence = [content_length_same_as_file_size,
                          file_has_right_extension,
                          file_has_right_content_type,
                          file_size_is_below_maximum]

    end_on_failure_validators = []

    for validator in validator_sequence:
        code, message = validator(file_info)
        logging.info(f"validation - {validator.__name__}: {code}")
        if code != 200:
            messages.append(message)
            if not status_code:
                status_code = code
            if validator in end_on_failure_validators:
                break

    if not status_code:
        status_code = 200
    return ValidationResponse(status_code=status_code, message=messages)


def content_length_same_as_file_size(file_info: FileInfo):
    if file_info.content_length == file_info.size:
        return 200, ""
    else:
        return 400, "Content length does not match file size"


def file_has_right_extension(file_info: FileInfo):
    if file_info.filename.endswith('.xlsx'):
        return 200, ""
    else:
        return 415, "File extension is not .xlsx"


def file_has_right_content_type(file_info: FileInfo):
    if file_info.content_type == "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet":
        return 200, ""
    else:
        return 415, "File is of wrong type"


def file_size_is_below_maximum(file_info: FileInfo):
    if file_info.size <= 2000000:
        return 200, ""
    else:
        return 413, "File size suspiciously large (over 2000000 bytes)"
