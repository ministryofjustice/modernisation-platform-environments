output "name" {
  value = join(",", aws_glue_job.glue_job.*.id)
}