from pyspark.sql import SparkSession

# Initialize SparkSession
spark = SparkSession.builder.appName("RDS to S3 Data Transformation").getOrCreate()

# Read table names from Glue Data Catalog
glueContext = GlueContext(spark.sparkContext)
table_names = glueContext.extract_schema_from_catalog(database="test")

# Loop through table names and process each table
for table_name in table_names:
    # Load data from RDS into Spark DataFrame
    jdbc_url = "jdbc:sqlserver://your_rds_host:1433/test"
    properties = {
        "user": "admin",
        "password": secret,
        "driver": "org.sqlserver.Driver",
    }
    df = spark.read.jdbc(url=jdbc_url, table=table_name, properties=properties)

    # Write transformed data to S3 in Parquet format
    output_path = f"s3a://output-bucket/output/{table_name}"
    df.write.mode("overwrite").parquet(output_path)

# Stop SparkSession
spark.stop()
