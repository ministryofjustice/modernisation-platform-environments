output "lambda_dms_replication_metric_py_hash" {
    value = filemd5(local_file.lambda_dms_replication_metric_py.filename)
}

output "lambda_dms_replication_metric_zip_path" {
    value = data.archive_file.lambda_dms_replication_metric_zip.output_path
}