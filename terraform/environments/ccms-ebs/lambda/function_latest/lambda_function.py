import logging
from config.database_config import get_database_environment_settings
from datalayer.excel_manager import process_file
from datalayer.s3_manager import PaymentS3Bucket
from businesslayer.provider_acount_check_manager import provider_account_check
from businesslayer.payment_load_manager import process_payment_load
from validation.validate import validate_request

logger = logging.getLogger(__name__)


# For convenient AWS running, this function needs to be called lambda_handler
def lambda_handler(event, context):
    """Upload monthly payment load spreadsheet"""
    environment_settings = get_database_environment_settings()

    response = {"excel_files": None,
                "validation_response": None,
                "upload_file_result": None,
                "file_errors": [],
                "success": False}

    logging.info("start_upload_file")
    filebucket = PaymentS3Bucket(environment_settings.s3_bucket_name)
    response["excel_files"] = filebucket.list_pending_excel_files()

    if len(response["excel_files"]) != 1:
        error_message = f"Must have a single .xlsx file. Found: {response['excel_files']}"
        logging.error(f"upload_file_error: {error_message}")
        response["file_errors"].append(error_message)
    else:
        filename = response["excel_files"][0].filename
        if filename in filebucket.list_processed_filenames():
            error_message = f"Filename {filename} already present in 'completed' folder"
            logging.error(f"upload_file_error: {error_message}")
            response["file_errors"].append(error_message)
        response["validation_response"] = validate_request(response["excel_files"][0])
        if response["validation_response"].status_code != 200:
            error_message = f"upload_file_validation_error: {response['validation_response']}"
            logging.error(error_message)

    if not response["file_errors"] and response["validation_response"].status_code == 200:
        file_content = filebucket.get_file_content(filename)
        payment_load_data = process_file(file_content, name=filename)
        provider_check_result = provider_account_check(payment_load_data)
        response["upload_file_result"] = process_payment_load(payment_load_data, provider_check_result)
        if response["upload_file_result"].payment_load_result.failed_payment_count == 0:
            filebucket.move_file_to_processed(filename)
            logging.info(f"finish_upload_file: {filename}, Number of payments loaded:" +
                         str(response.get("upload_file_result").payment_load_result.committed_payment_count))
            response["success"] = True
        else:
            filebucket.move_file_to_failed(filename)
            logging.error(f"upload_file_error: {filename} Failed payments: " +
                          str(response["upload_file_result"].payment_load_result.failed_payment_count))

    return make_json_friendly_response(response)


def make_json_friendly_response(response):
    """
    We hold a lot of response data in Pydantic BaseModel objects but these are not
    conveniently JSON serialisable and AWS needs a response that json.dumps()
    can digest. This function converts the BaseModel objects within the response
    into standard Python dictionaries, which do have JSON compatibility that AWS needs.
    """
    if response["excel_files"] is not None:
        response["excel_files"] = [e.dict() for e in response["excel_files"]]

    if response["validation_response"] is not None:
        response["validation_response"] = response["validation_response"].dict()

    if response["upload_file_result"] is not None:
        # We've three nested BaseModels here: upload_file_result, payment_load_result, failed_payment_details (in list)
        # The .dict() method is recursive, so covers all in one go.
        response["upload_file_result"] = response["upload_file_result"].dict()
    return response
