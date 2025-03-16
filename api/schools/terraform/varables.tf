variable "environment" {
  type = string
}

variable "ecr_image_uri" {
  description = "The URI of the ECR image for the SageMaker endpoint"
  type        = string
}

variable "sagemaker_instance_type" {
  description = "The instance type for the SageMaker endpoint"
  type        = string
  default     = "ml.t2.medium"
}

variable "sagemaker_endpoint_name" {
  description = "The name of the SageMaker endpoint"
  type        = string
  default     = "school-district-query-endpoint"
}

variable "custom_authorizer_lambda_name" {
  type = string
}

variable "custom_authorizer_lambda_arn" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "base_path" {
  type = string
}
