
from models.payment_load import PaymentLoad
from models.provider_check import ProviderCheckResult
from datalayer.provider_check import GetProviderDetails


def provider_account_check(payment_load_data: PaymentLoad) -> ProviderCheckResult:
    provider_account_nos = payment_load_data.get_distinct_account_nos()
    provider_source = GetProviderDetails()
    results, not_found, errors = provider_source.get_provider_names(provider_account_nos)
    return ProviderCheckResult(provider_names=results,
                               provider_count=len(provider_account_nos),
                               missing_provider_count=len(not_found),
                               missing_provider_account_nos=not_found,
                               unexpected_errors=errors)
