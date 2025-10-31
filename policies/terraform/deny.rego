package main

deny[msg] {
	input.terraform.backend
  msg = sprintf("Adding %v is not allowed",["backends"])
}

deny[msg] {
	input.provider
  msg = sprintf("Adding %v is not allowed",["providers"])
}
