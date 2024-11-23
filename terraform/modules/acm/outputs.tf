output "certificate_arn" {
  value = aws_acm_certificate.config_cert.arn
}

output "domain_validation_options" {
  value       = aws_acm_certificate.config_cert.domain_validation_options
  description = "Domain validation options for the ACM certificate."
}
