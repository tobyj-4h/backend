resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in var.domain_validation_options : dvo.domain_name => {
      name    = dvo.resource_record_name
      type    = dvo.resource_record_type
      value   = dvo.resource_record_value
      zone_id = var.hosted_zone_id
    }
  }
  zone_id = each.value.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.value]
}


resource "aws_route53_record" "backend_api_alias" {
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"
  alias {
    name                   = var.api_gateway_domain_name
    zone_id                = var.api_gateway_zone_id
    evaluate_target_health = false
  }
}
