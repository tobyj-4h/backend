variable "domain_name" {
  type        = string
  description = "The custom domain name for the API (e.g., config.fourhorizonsed.com)"
}

variable "hosted_zone_id" {
  type        = string
  description = "The Route53 hosted zone ID for the domain"
}

variable "environment" {
  type = string
}

variable "user_pool_id" {
  type = string
}
