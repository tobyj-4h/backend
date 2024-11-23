output "api_gateway_domain_name" {
  value       = aws_api_gateway_domain_name.custom_domain.cloudfront_domain_name
  description = "The custom domain name for the API Gateway"
}

output "api_gateway_zone_id" {
  value       = aws_api_gateway_domain_name.custom_domain.cloudfront_zone_id
  description = "The hosted zone ID for the API Gateway custom domain"
}
