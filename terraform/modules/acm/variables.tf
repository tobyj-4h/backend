variable "domain_name" {
  type = string
}

variable "validation_record_fqdns" {
  description = "List of FQDNs for the Route 53 validation records for the ACM certificate."
  type        = list(string)
}

