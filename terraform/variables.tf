variable "lambda_config" {
  type = object({
    zip_name      = string
    runtime       = string
    handler       = string
    function_name = string
  })
}