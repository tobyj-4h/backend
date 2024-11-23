variable "hosted_zone_id" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "api_gateway_domain_name" {
  type = string
}

variable "api_gateway_zone_id" {
  type = string
}

variable "domain_validation_options" {
  description = "Domain validation options for the ACM certificate."
  type = list(object({
    domain_name           = string
    resource_record_name  = string
    resource_record_type  = string
    resource_record_value = string
  }))
}

