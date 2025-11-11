from pydantic import BaseModel


class ProviderCheckResult(BaseModel):
    provider_count: int
    missing_provider_count: int
    provider_names: dict[str, str]
    missing_provider_account_nos: list[str]
    unexpected_errors: dict[str, str]

    def get_unexpected_errors_summary(cls) -> list[str]:
        """Return list containing any unique 'unexpected errors'.
        Has advantage of being more concise than unexpected_errors
        which can repeat the same error message for each provider account.
        """
        return list(set(cls.unexpected_errors.values()))
