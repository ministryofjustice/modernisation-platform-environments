import sys
import hashlib
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

# Initialize Glue context
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'JDBC_URL', 'JDBC_TABLE', 'JDBC_USER', 'JDBC_PASSWORD', 'S3_TARGET_PATH'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Parameters
jdbc_url = args['JDBC_URL']
jdbc_table = args['JDBC_TABLE']
jdbc_user = args['JDBC_USER']
jdbc_password = args['JDBC_PASSWORD']
target_path = args['S3_TARGET_PATH']

# Read source data from RDS using JDBC
source_df = spark.read.format('jdbc') \
    .option('url', jdbc_url) \
    .option('dbtable', jdbc_table) \
    .option('user', jdbc_user) \
    .option('password', jdbc_password) \
    .load()

# Read target data from S3
target_df = spark.read.format('parquet').load(target_path)

# Function to compute checksum (MD5 hash) of a row
def compute_checksum(row):
    row_string = ''.join([str(elem) for elem in row])
    return hashlib.md5(row_string.encode('utf-8')).hexdigest()

# Compute checksums for source and target data
source_with_checksum = source_df.withColumn('checksum', compute_checksum(source_df.collect()))
target_with_checksum = target_df.withColumn('checksum', compute_checksum(target_df.collect()))

# Compute row counts
source_row_count = source_df.count()
target_row_count = target_df.count()

# Compare row counts
if source_row_count != target_row_count:
    print(f"Row count mismatch: Source ({source_row_count}) vs Target ({target_row_count})")
else:
    print("Row count matches")

# Compare checksums
source_checksums = set(source_with_checksum.select('checksum').rdd.flatMap(lambda x: x).collect())
target_checksums = set(target_with_checksum.select('checksum').rdd.flatMap(lambda x: x).collect())

if source_checksums != target_checksums:
    print("Data integrity check failed: Checksums do not match")
else:
    print("Data integrity check passed: Checksums match")

# Commit job
job.commit()