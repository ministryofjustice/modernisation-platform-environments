from datalayer.payment_load import PaymentLoader
from models.payment_load import PaymentLoad, PaymentLoadResult
from models.provider_check import ProviderCheckResult
from models.upload_file_result import UploadFileResponse
from config.database_config import get_database_environment_settings


def process_payment_load(payment_load_data: PaymentLoad,
                         provider_check_result: ProviderCheckResult) -> UploadFileResponse:
    environment_settings = get_database_environment_settings()
    excel_payment_row_count = len(payment_load_data.payment_rows)

    if provider_check_result.missing_provider_count == 0:
        # Full load if no missing providers
        accepted_row_count = len(payment_load_data.payment_rows)
    else:
        if environment_settings.is_production:
            # No load if missing providers and environment is production
            accepted_row_count = 0
        else:
            # Partial load if missing providers and environment is not production
            acceptable_rows = [row for row in payment_load_data.payment_rows
                               if row.account_no in provider_check_result.provider_names]
            accepted_row_count = len(acceptable_rows)
            payment_load_data.payment_rows = acceptable_rows

    if accepted_row_count > 0:
        loader = PaymentLoader()
        result = loader.load_payment_set(payment_load_data,
                                         provider_check_result.provider_names,
                                         environment_settings.is_production)
    else:
        result = PaymentLoadResult(failed_payment_details=[], environment_errors=[])
        result.failed_payment_count = len(payment_load_data.payment_rows)

    return UploadFileResponse(
        is_production=environment_settings.is_production,
        excel_payment_row_count=excel_payment_row_count,
        accepted_payments_after_provider_check=accepted_row_count,
        provider_accounts_not_found=provider_check_result.missing_provider_account_nos,
        provider_unexpected_errors_summary=provider_check_result.get_unexpected_errors_summary(),
        payment_load_result=result)
