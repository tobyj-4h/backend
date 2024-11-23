# output "api_gateway_domain_name" {
#   value       = aws_api_gateway_domain_name.config_custom_domain.cloudfront_domain_name
#   description = "The custom domain name for the API Gateway"
# }

# output "api_gateway_zone_id" {
#   value       = aws_api_gateway_domain_name.config_custom_domain.cloudfront_zone_id
#   description = "The hosted zone ID for the API Gateway custom domain"
# }

# output "api_gateway_invoke_url" {
#   value       = "${aws_api_gateway_rest_api.config_api.execution_arn}/${aws_api_gateway_stage.config_api_stage.stage_name}"
#   description = "The invoke URL for the API Gateway"
# }
