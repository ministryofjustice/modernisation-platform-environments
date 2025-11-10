from typing import Iterable
from datalayer.database import DbConnection


class GetProviderDetails(DbConnection):
    def get_provider_names(self, account_nos: Iterable[str]) -> tuple[dict[str, str], list[str], dict[str, str]]:
        provider_sql = """
        select vendor_site_code_alt
        from ap_supplier_sites_all
        where vendor_site_code = :account_no
        """

        provider_names = {}
        not_found = []
        errors = {}
        for account_no in account_nos:
            rows, error = self.run_query(provider_sql, params=[account_no])
            if rows:
                provider_names[account_no] = rows[0][0]
            else:
                not_found.append(account_no)
            if error:
                errors[account_no] = error
        self.disconnect()
        return provider_names, not_found, errors
