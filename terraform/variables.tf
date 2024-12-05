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

variable "school_district_query_sagemaker_ecr_image_uri" {
  description = "The URI of the ECR image for the SageMaker endpoint"
  type        = string
}

variable "school_district_query_sagemaker_instance_type" {
  description = "The instance type for the SageMaker endpoint"
  type        = string
  default     = "ml.t2.medium"
}

variable "school_district_query_sagemaker_endpoint_name" {
  description = "The name of the SageMaker endpoint"
  type        = string
  default     = "school-district-query-endpoint"
}
