variable "function_to_iterate" { 
    type = object({
        lambda_function_arn  = string
        lambda_function_name = string
    })
}
