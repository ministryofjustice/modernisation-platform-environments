import datetime
from pydantic import BaseModel, validator


"""
This module provides data required by the two CCMS invoice staging tables
(XXCCMS_AP_INVOICES_STG and XXCCMS_AP_INVOICE_LINES_STG ) that's
not sourced from the payment load spreadsheet.

Note PAYMENT_SOURCE below is the SOURCE value loaded into XXCCMS_AP_INVOICES_STG
This has impact on how payments are processed in CCMS and needs to be set to
a predefined value that exists within CCMS. It also determines whether CCMS will
return payment feedback/confirmation based on how it is defined within CCMS.
"""

PAYMENT_SOURCE = "PAYMENT LOAD"


class PaymentExtraParameters(BaseModel):
    """Additional parameters for each payment that can vary within or between loads"""
    invoice_num: str
    date: str
    provider_name: str

    @validator('invoice_num')
    def invoice_num_is_not_too_long(cls, invoice_num):
        if len(invoice_num) > 50:
            raise ValueError(f"invoice_num '{invoice_num}' exceeds 50 char limit")
        return invoice_num

    @validator('date')
    def date_is_in_wrong_format(cls, date):
        try:
            datetime.datetime.strptime(date, "%d-%b-%Y")
        except ValueError:
            raise ValueError(f"date '{date}' not in '%d-%b-%Y' format")
        return date


class PaymentTypeParameters(BaseModel):
    """Fixed parameters for each payment type"""
    # invoice - values depend on payment type
    pay_group_lookup_code: str
    invoice_type: str
    gl_account_combination: str

    # invoice lines - value depends on payment type
    description: str

    # invoice - fixed values
    case_reference: str = "**NO REFERENCE**"
    invoice_currency_code: str = "GBP"
    no_xrate_base_amount: int = 1
    org_name: str = "LSC Fund Operating Unit"
    payment_method_code: str = "LSC BACS"
    terms_name: str = "IMMEDIATE"
    source: str = PAYMENT_SOURCE
    requested_amount: int = 0  # Always zero - does not affect payment value

    # invoice lines - fixed values
    amount_includes_tax_flag: str = "N"
    set_of_books_name: str = "LSC Fund"
    tax_code: str = "CIS_VAT_OTHER"
    unit_price: int = 1


payment_type_param_source = {}

payment_type_param_source["CIVIL"] = PaymentTypeParameters(
    description=" ",
    pay_group_lookup_code="LEGAL HELP",
    invoice_type="SPANBILL",
    gl_account_combination="01.12.99.000.6140.0000")

payment_type_param_source["CRIME"] = PaymentTypeParameters(
    description=" ",
    pay_group_lookup_code="CRIME LOWER",
    invoice_type="SPOCCBILL",
    gl_account_combination="01.21.99.000.6140.0000")

payment_type_param_source["MEDIATION"] = PaymentTypeParameters(
    description="MEDSMP15",
    pay_group_lookup_code="MEDIATION",
    invoice_type="MEDREGBILL",
    gl_account_combination="01.11.99.000.2014.0000")
