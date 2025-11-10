import logging
import time
from datetime import date
from oracledb import DatabaseError
from datalayer.database import DbConnection
from datalayer.username_trim import username_trim
from models.payment_load import PaymentLoadResult, PaymentError, DatabaseCallResult
from config.payment_load_config import PaymentExtraParameters, payment_type_param_source


class PaymentLoader(DbConnection):

    def load_payment_set(self, payment_load_data, provider_names, is_production=True) -> PaymentLoadResult:
        logging.info(f"start_load_payment_set: production={is_production}")
        result = PaymentLoadResult(failed_payment_details=[], environment_errors=[])

        try:
            self.connect()
        except DatabaseError as err:
            logging.error(f"Database connection failed: '{err}'")
            result.environment_errors.append(str(err))
            return result

        invoice_num_maker = InvoiceNumMaker()
        invoice_num_maker.fixed_text = (f"{username_trim(payment_load_data.os_username, 16)}"
                                        f"-{payment_load_data.name[-12:]}")

        for payment in payment_load_data.payment_rows:
            payment_extra_parameters = PaymentExtraParameters(invoice_num=invoice_num_maker.new_reference(),
                                                              date=date.today().strftime("%d-%b-%Y"),
                                                              provider_name=provider_names.get(payment.account_no))
            payment_type_parameters = payment_type_param_source.get(payment.area_of_law)
            load_result = self.load_payment(payment, payment_type_parameters, payment_extra_parameters)
            if load_result.err_loc is None and load_result.err_msg is None:
                result.acceptable_payment_count += 1
                if result.first_invoice_num == "":
                    result.first_invoice_num = load_result.invoice_num
                result.last_invoice_num = load_result.invoice_num
                if not is_production:
                    self.connection.commit()
                    result.committed_payment_count += 1
            else:
                result.failed_payment_details.append(PaymentError(payment=payment,
                                                                  error_code=load_result.err_loc,
                                                                  error_message=load_result.err_msg))
                self.connection.rollback()

        if not result.failed_payment_details:
            self.connection.commit()
            result.committed_payment_count = result.acceptable_payment_count
        else:
            self.connection.rollback()

        self.disconnect()
        result.failed_payment_count = len(result.failed_payment_details)

        logging.info(f"finish_load_payment_set: payments committed={result.committed_payment_count}, "
                     f"failed payment count={result.failed_payment_count}, "
                     f"first invoice_num={result.first_invoice_num}, "
                     f"last invoice_num={result.last_invoice_num}"
                     )
        return result

    def load_payment(self, payment, payment_type_parameters, payment_extra_parameters):
        err_loc = None
        err_msg = None
        invoice_row_data = make_invoice_data(payment,
                                             payment_type_parameters,
                                             payment_extra_parameters)
        invoice_line_row1_data = make_invoice_line_data(payment,
                                                        payment_type_parameters,
                                                        payment_extra_parameters,
                                                        vat_line=False)
        invoice_line_row2_data = make_invoice_line_data(payment,
                                                        payment_type_parameters,
                                                        payment_extra_parameters,
                                                        vat_line=True)
        insert_steps = [(invoice_sql, invoice_row_data),
                        (invoice_line_sql, invoice_line_row1_data),
                        (invoice_line_sql, invoice_line_row2_data)]

        for step_count, (sql, params) in enumerate(insert_steps):
            rowcount, error = self.insert_row(sql, params)
            if error:
                err_loc, err_msg = database_error_split(error)
                break
            if rowcount != 1:
                err_loc = "-1"
                err_msg = f"Step {step_count}: wrong rowcount- expected 1, got{rowcount}"
                break

        result = DatabaseCallResult(invoice_num=payment_extra_parameters.invoice_num, err_loc=err_loc, err_msg=err_msg)
        return result


invoice_sql = """
insert into XXCCMS_AP_INVOICES_STG (RECORD_STATUS,
                                    SOURCE_TIMESTAMP,
                                    RECORD_TYPE,
                                    CASE_REFERENCE,
                                    DESCRIPTION,
                                    INVOICE_AMOUNT,
                                    INVOICE_CURRENCY_CODE,
                                    INVOICE_DATE,
                                    INVOICE_NUM,
                                    INVOICE_RECEIVED_DATE,
                                    NO_XRATE_BASE_AMOUNT,
                                    ORG_NAME,
                                    PAY_GROUP_LOOKUP_CODE,
                                    PAYMENT_METHOD_CODE,
                                    TERMS_NAME,
                                    VENDOR_NAME,
                                    VENDOR_SITE_CODE,
                                    SOURCE,
                                    STAGING_TIMESTAMP,
                                    INVOICE_TYPE,
                                    REQUESTED_AMOUNT)
values (
:record_status,
SYSDATE,
:record_type,
:case_reference,
:description,
:invoice_amount,
:invoice_currency_code,
:invoice_date,
:invoice_num,
:invoice_received_date,
:no_xrate_base_amount,
:org_name,
:pay_group_lookup_code,
:payment_method_code,
:terms_name,
:vendor_name,
:vendor_site_code,
:source,
SYSDATE,
:invoice_type,
:requested_amount
)
"""


invoice_line_sql = """
insert into XXCCMS_AP_INVOICE_LINES_STG (RECORD_STATUS,
                                        SOURCE_TIMESTAMP,
                                        RECORD_TYPE,
                                        AMOUNT,
                                        AMOUNT_INCLUDES_TAX_FLAG,
                                        DESCRIPTION,
                                        LEGACY_INVOICE_REFERENCE,
                                        LINE_NUMBER,
                                        LINE_TYPE_LOOKUP_CODE,
                                        QUANTITY_INVOICED,
                                        ACCOUNT_COMBINATION,
                                        SET_OF_BOOKS_NAME,
                                        TAX_CODE,
                                        UNIT_PRICE,
                                        STAGING_TIMESTAMP)
values(
    :record_status,
    SYSDATE,
    :record_type,
    :amount,
    :amount_includes_tax_flag,
    :description,
    :legacy_invoice_reference,
    :line_number,
    :line_type_lookup_code,
    :quantity_invoiced,
    :account_combination,
    :set_of_books_name,
    :tax_code,
    :unit_price,
    SYSDATE
    )
    """


class InvoiceNumMaker:
    def __init__(self, fixed_text="", max_tries=10):
        self.created_values = set()
        self.fixed_text = fixed_text[-19:]
        self.max_tries = max_tries

    def new_reference(self):
        for _ in range(self.max_tries):
            new_ref = f"{self.fixed_text}-{time.time():.7f}"
            if new_ref not in self.created_values:
                self.created_values.add(new_ref)
                return new_ref
            time.sleep(0.000001)
        raise ValueError(f"Non-unique value received ({new_ref})")


def make_invoice_data(payment, payment_type_parameters, payment_extra_parameters):
    invoice_data = {
        "record_status": "NEW",
        "record_type": "I",
        "case_reference": payment_type_parameters.case_reference,
        "description": payment_type_parameters.description,
        "invoice_amount": payment.amount,
        "invoice_currency_code": payment_type_parameters.invoice_currency_code,
        "invoice_date": payment_extra_parameters.date,
        "invoice_num": payment_extra_parameters.invoice_num,
        "invoice_received_date": payment_extra_parameters.date,
        "no_xrate_base_amount": payment_type_parameters.no_xrate_base_amount,
        "org_name": payment_type_parameters.org_name,
        "pay_group_lookup_code": payment_type_parameters.pay_group_lookup_code,
        "payment_method_code": payment_type_parameters.payment_method_code,
        "terms_name": payment_type_parameters.terms_name,
        "vendor_name": payment_extra_parameters.provider_name,
        "vendor_site_code": payment.account_no,
        "source": payment_type_parameters.source,
        "invoice_type": payment_type_parameters.invoice_type,
        "requested_amount": payment_type_parameters.requested_amount
    }
    return invoice_data


def make_invoice_line_data(payment, payment_type_parameters, payment_extra_parameters, vat_line=False):
    line_number = 1
    line_type = "ITEM"
    local_amount = payment.amount
    if vat_line:
        local_amount = 0
        line_number = 2
        line_type = "TAX"

    invoice_line_data = {
        "record_status": "NEW",
        "record_type": "I",
        "amount": local_amount,
        "amount_includes_tax_flag": payment_type_parameters.amount_includes_tax_flag,
        "description": payment_type_parameters.description,
        "legacy_invoice_reference": payment_extra_parameters.invoice_num,
        "line_number": line_number,
        "line_type_lookup_code": line_type,
        "quantity_invoiced": local_amount,
        "account_combination": payment_type_parameters.gl_account_combination,
        "set_of_books_name": payment_type_parameters.set_of_books_name,
        "tax_code": payment_type_parameters.tax_code,
        "unit_price": payment_type_parameters.unit_price
    }
    return invoice_line_data


def database_error_split(err) -> tuple[str, str]:
    """
    oracledb.DatabaseError exceptions contain error message with an error code,
    then a colon, then error message, e.g. "ORA-01017: invalid username/password; logon denied"
    This function extracts the error code and message, then returns them as separate strings.
    This is for consistency with the way errors are reported by the the CIS PL/SQL procedure.
    """
    error_code, error_text = str(err).split(":", 1)
    return error_code, error_text.strip()
