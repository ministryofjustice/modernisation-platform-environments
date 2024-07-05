import sys
from datetime import datetime, timedelta
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

# Read source data from RDS using JDBC and a filter for predicate pushdown
#pushDownQuery = """(select city_id, count(1) as cnt from sales_csv group by city_id) as sales_csv"""
source_df = spark.read.format('jdbc') \
    .option('url', jdbc_url) \
    .option('dbtable', jdbc_table) \
    .option('user', jdbc_user) \
    .option('password', jdbc_password) \
    .load() \
    .filter("<filter here>")

    #.option("dbtable", pushDownQuery) \ <-- maybe might need this.

#####################################
# Define Partitioning strategy here #
#####################################

## # Define the start and end dates for partitioning
## start_date = datetime(2023, 1, 1)
## end_date = datetime(2023, 12, 31)
## 
## # Function to generate month ranges
## def month_range(start_date, end_date):
##     start = start_date.replace(day=1)
##     end = end_date.replace(day=1)
##     while start <= end:
##         yield start
##         start += timedelta(days=32)
##         start = start.replace(day=1)
## 


############################
# Loop over each partition #
############################

#for month_start in month_range(start_date, end_date):
#    month_end = (month_start + timedelta(days=32)).replace(day=1) - timedelta(days=1)
#    push_down_predicate = f"transaction_date >= '{month_start.strftime('%Y-%m-%d')}' AND transaction_date <= '{month_end.strftime('%Y-%m-%d')}'"
#    
#    # Read data from RDS with pushdown predicate
#    datasource = glueContext.create_dynamic_frame.from_catalog(
#        database="my_database",
#        table_name="my_table",
#        push_down_predicate=push_down_predicate
#    )
#    
#    # Perform any necessary transformations
#    transformed_data = datasource
#    #transformed_data = ApplyMapping.apply(
#    #    frame=datasource,
#    #    mappings=[("id", "string", "id", "string"), ("name", "string", "name", "string")]
#    #) OR
#    # Read schema information
#    #schema_query = "(SELECT * FROM information_schema.columns WHERE table_schema = 'your_database' AND table_name = 'your_table') AS schema_info"
#    #schema_df = spark.read.jdbc(url=jdbc_url, table=schema_query, properties=connection_properties)
#    #
#    ## Extract schema information
#    #columns = schema_df.select("COLUMN_NAME", "DATA_TYPE").collect()
#    #
#    ## Map data types to Spark types
#    #type_mapping = {
#    #    "varchar": StringType(),
#    #    "int": IntegerType(),
#    #    "date": DateType(),
#    #    # Add other necessary mappings
#    #}
#    #
#    #fields = [StructField(row['COLUMN_NAME'], type_mapping[row['DATA_TYPE']], True) for row in columns]
#    #schema = StructType(fields)
#    
#    # Write the partitioned data to S3
#    output_path = f"s3://my-bucket/output/year={month_start.year}/month={month_start.month}/"
#    glueContext.write_dynamic_frame.from_options(
#        frame=transformed_data,
#        connection_type="s3",
#        connection_options={"path": output_path},
#        format="parquet"
#    )
#
#job.commit()