import os
import re
import json
import boto3
import awswrangler as wr
import pandas as pd
from datetime import datetime
from awswrangler.exceptions import AlreadyExists

GLUE_DATABASE = os.getenv("GLUE_DATABASE")
PARQUET_PREFIX = os.getenv("PARQUET_PREFIX", "")

s3 = boto3.client("s3")

TIMESTAMP_RE = re.compile(
    r"""^
    (?P<name>.+?)          # everything up to the underscore before timestamp
    _(?P<ts>\d{8}\d{6})   # YYYYMMDDHHMMSS
    \.csv$
    """,
    re.VERBOSE | re.IGNORECASE,
)

def sanitize_table_name(name: str) -> str:
    n = re.sub(r"[^a-zA-Z0-9_]", "_", name).lower()
    if not re.match(r"^[a-z]", n):
        n = f"t_{n}"
    return n[:255]

def parse_key(key: str) -> tuple[str, str]:
    fn = key.split("/")[-1]
    m = TIMESTAMP_RE.match(fn)
    if not m:
        raise ValueError(
            f"csv_upload_key '{key}' must look like Name_YYYYMMDDHHMMSSZ.csv"
        )
    return m.group("name"), m.group("ts")

def ensure_database(db_name: str):
    try:
        wr.catalog.create_database(name=db_name, exist_ok=True)
    except AlreadyExists:
        pass  # safe to ignore if a concurrent create sneaks through

def _deduplicate_columns(df: pd.DataFrame) -> pd.DataFrame:
    """
    Ensure all column names are unique and Glue-safe.
    If duplicates exist after sanitization, suffix with _1, _2, ...
    """
    seen = {}
    new_cols = []
    for col in df.columns:
        base = re.sub(r"[^a-zA-Z0-9_]", "_", col).lower().strip("_")
        if base in seen:
            seen[base] += 1
            new_cols.append(f"{base}_{seen[base]}")
        else:
            seen[base] = 0
            new_cols.append(base)
    df.columns = new_cols
    return df

def _clean_nbsp_and_strip(df: pd.DataFrame) -> pd.DataFrame:
    # Normalize headers
    df.columns = [c.replace("\u00A0", " ").strip() for c in df.columns]
    # Normalize string/object cells
    obj_cols = df.select_dtypes(include=["object"]).columns
    for c in obj_cols:
        # Preserve NaNs; only operate on strings
        df[c] = df[c].map(lambda x: x.replace("\u00A0", " ").strip() if isinstance(x, str) else x)
    return df

def read_csv_safely(s3_uri: str, explicit_encoding: str | None = None) -> pd.DataFrame:
    """
    Try common encodings and let pandas infer the delimiter.
    Prefer an explicit encoding if provided via env/event.
    """
    encodings = [explicit_encoding] if explicit_encoding else []
    encodings += ["utf-8", "utf-8-sig", "cp1252", "iso-8859-1"]
    tried = []
    for enc in [e for e in encodings if e]:
        try:
            # engine='python' + sep=None => sniff delimiter robustly
            return wr.s3.read_csv(
                s3_uri,
                encoding=enc,
                sep=None,
                engine="python",
                dtype_backend="pyarrow",
                on_bad_lines="skip",      # skip malformed rows rather than failing
            )
        except UnicodeDecodeError:
            tried.append(enc)
            continue
    raise UnicodeDecodeError(
        "csv", b"", 0, 1,
        f"Failed to decode with encodings tried: {', '.join(tried)}"
    )

def _stabilize_dtypes(df: pd.DataFrame) -> pd.DataFrame:
    """
    Make Athena-friendly types:
    - All-null object columns -> string
    - Low-cardinality boolean-like text -> boolean
    - Parse datetimes when obvious
    - Otherwise object -> string
    """
    obj_cols = df.select_dtypes(include=["object"]).columns
    for c in obj_cols:
        col = df[c]

        # All-null?
        if not col.notna().any():
            df[c] = col.astype("string")
            continue

        sample = col.dropna().astype(str).str.strip()
        lower = sample.str.lower()

        # boolean-like?
        truthy = {"true","t","yes","y","1"}
        falsy  = {"false","f","no","n","0"}
        unique_vals = set(lower.unique())
        if unique_vals.issubset(truthy | falsy) and len(unique_vals) <= 2:
            df[c] = lower.map(lambda x: True if x in truthy else (False if x in falsy else pd.NA)).astype("boolean")
            continue

        # datetime-like?
        dt = pd.to_datetime(sample, errors="coerce", utc=False, infer_datetime_format=True)
        if dt.notna().mean() >= 0.9:  # 90%+ parseable -> treat as datetime
            df[c] = pd.to_datetime(col, errors="coerce")
            continue

        # numeric-like?
        num = pd.to_numeric(sample.str.replace(",", ""), errors="coerce")
        if num.notna().mean() >= 0.9:
            # choose int if all numeric are integers, else float
            if (num.dropna() % 1 == 0).all():
                df[c] = pd.to_numeric(col.astype(str).str.replace(",", ""), errors="coerce").astype("Int64")
            else:
                df[c] = pd.to_numeric(col.astype(str).str.replace(",", ""), errors="coerce")
            continue

        # default: string (pandas string dtype)
        df[c] = col.astype("string")

    return df

def handler(event, context):
    """
    Event:
    {
      "csv_upload_bucket": "...",
      "csv_upload_key": "Asset_20250902103213Z.csv",
      "extraction_timestamp": "20250902103213Z",
      "output_bucket": "...",
      "name": "concept"   
    }
    """
    csv_bucket = event["csv_upload_bucket"]
    csv_key = event["csv_upload_key"]
    extraction_ts = event["extraction_timestamp"]
    out_bucket = event["output_bucket"]
    project_name = event.get("name", "default")
    forced_encoding = event.get("encoding") or os.getenv("CSV_ENCODING")

    base_name, ts_from_key = parse_key(csv_key)
    ts = extraction_ts or ts_from_key
    table_name = sanitize_table_name(base_name)
    glue_db = GLUE_DATABASE or sanitize_table_name(project_name)

    input_path = f"s3://{csv_bucket}/{csv_key}"
    base_prefix = f"{PARQUET_PREFIX.strip('/')}/" if PARQUET_PREFIX else ""
    dataset_root = f"s3://{out_bucket}/{base_prefix}{table_name}/"

    ensure_database(glue_db)

    # Robust CSV read + cleanup
    df = read_csv_safely(input_path, explicit_encoding=forced_encoding)
    df = _clean_nbsp_and_strip(df)
    df = _deduplicate_columns(df)
    df = _stabilize_dtypes(df)
    # Add partition column
    df["extraction_timestamp"] = ts

    # Write Parquet + update Glue catalog
    wr.s3.to_parquet(
        df=df,
        path=dataset_root,
        dataset=True,
        partition_cols=["extraction_timestamp"],
        database=glue_db,
        table=table_name,
        schema_evolution=True,
        # If writing many small files, consider max_rows_by_file to coalesce:
        # max_rows_by_file=500_000,
    )

    return {
        "status": "ok",
        "table": table_name,
        "database": glue_db,
        "dataset_root": dataset_root,
        "partition_written": ts,
        "records": len(df),
        "encoding_used": forced_encoding or "auto-detected",
    }
