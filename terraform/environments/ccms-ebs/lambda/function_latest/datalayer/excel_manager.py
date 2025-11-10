import logging
import getpass
import openpyxl
from config.excel_manager_config import get_required_columns
from models.payment_load import PaymentLoad, PaymentRow
from pydantic import parse_obj_as, ValidationError
from io import BytesIO
from zipfile import BadZipFile


def process_file(file: bytes, name: str = "") -> PaymentLoad:
    logging.info("start_excel_reader_read_file")
    try:
        excel = openpyxl.load_workbook(filename=BytesIO(file), keep_vba=False)
        columns_with_index = resolve_column_indexes(excel)
        details = [{title: row[col].value for col, title in columns_with_index.items()}
                   for row in excel.worksheets[0].iter_rows()][1:]
        payment_data = PaymentLoad(payment_rows=parse_obj_as(list[PaymentRow], details),
                                   name=name, os_username=getpass.getuser())
        logging.info(f"finish_excel_reader_read_file: Total row count="f"{str(len(payment_data.payment_rows))}")
        return payment_data
    except BadZipFile as e:
        logging.error("exception_BadZipFile_raised: message='Unable to read file'", exc_info=e)
        raise Exception("Unable to read file")
    except ValidationError as e:
        logging.error("exception_ValidationError_raised: message='Excel contains unexpected data'", exc_info=e)
        raise e


def resolve_column_indexes(workbook: openpyxl.Workbook) -> dict:
    target_columns = get_required_columns().column_headers
    columns_with_index = {}
    for cell in workbook.worksheets[0][1]:
        if cell.value in target_columns:
            columns_with_index.update({cell.col_idx - 1: cell.value})
    if len(columns_with_index) != 3:
        missing_headers = list(set(target_columns) - set(list(columns_with_index.values())))
        logging.error(f"resolve_column_indexes_failure: message='missing required columns: {missing_headers}'")
        raise Exception(f"Spreadsheet missing required columns:{missing_headers}")
    return columns_with_index
