from pydantic import BaseModel
from models.payment_load import PaymentLoadResult


class UploadFileResponse(BaseModel):
    is_production: bool
    excel_payment_row_count: int
    accepted_payments_after_provider_check: int
    provider_accounts_not_found: list[str]
    provider_unexpected_errors_summary: list[str]
    payment_load_result: PaymentLoadResult
