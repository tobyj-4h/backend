resource "aws_acm_certificate" "config_cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"
}

resource "aws_acm_certificate_validation" "config_cert_validation" {
  certificate_arn         = aws_acm_certificate.config_cert.arn
  validation_record_fqdns = var.validation_record_fqdns
}
