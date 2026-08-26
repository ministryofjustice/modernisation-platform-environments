output "arn" {
  value = aws_sfn_state_machine.this.arn
}

output "id" {
  value = replace(replace(replace(replace(aws_sfn_state_machine.this.id, ":", "-"), "/", "-"), "_", "-"), "arn", "")
}
