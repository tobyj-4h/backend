output "custom_authorizer_lambda_name" {
  value = aws_lambda_function.custom_authorizer_lambda.function_name
}

output "custom_authorizer_lambda_arn" {
  value = aws_lambda_function.custom_authorizer_lambda.arn
}
