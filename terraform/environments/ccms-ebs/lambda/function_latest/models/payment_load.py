from pydantic import BaseModel, Field, validator
import re


class PaymentRow(BaseModel):
    account_no: str = Field(..., alias='LSC Account Number')
    area_of_law: str = Field(..., alias='Area of Law')
    amount: float = Field(..., alias='Amount £')

    class Config:
        allow_population_by_field_name = True

    @validator('area_of_law')
    def area_of_law_has_correct_value(cls, area_of_law):
        if area_of_law not in ['CIVIL', 'CRIME', 'MEDIATION']:
            raise ValueError("area of law must be either CIVIL, CRIME or MEDIATION")
        return area_of_law

    @validator('account_no')
    def account_no_has_correct_format(cls, account_no):
        regex = re.compile(r"\d[A-Z]\d\d\d[A-Z]")
        if not re.fullmatch(regex, account_no):
            raise ValueError(f"account number {account_no} not in the correct format '1A111A'")
        return account_no


class PaymentLoad(BaseModel):
    payment_rows: list[PaymentRow] = []
    name: str = ""
    os_username: str = ""

    def get_distinct_account_nos(self) -> set[str]:
        return {row.account_no for row in self.payment_rows}


class PaymentError(BaseModel):
    payment: PaymentRow
    error_code: str
    error_message: str


class PaymentLoadResult(BaseModel):
    acceptable_payment_count: int = 0
    committed_payment_count: int = 0
    failed_payment_count: int = 0
    first_invoice_num: str = ""
    last_invoice_num: str = ""
    environment_errors: list[str]
    failed_payment_details: list[PaymentError]


class DatabaseCallResult(BaseModel):
    """The three key parameters from an individual payment load"""
    invoice_num: str | None
    err_loc: str | None
    err_msg: str | None
