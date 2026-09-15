locals {
    name       = trimprefix(var.function_to_iterate.lambda_function_name, "merge_")
    camel_name = replace(title(replace(local.name, "_", " ")), " ", "")
}
