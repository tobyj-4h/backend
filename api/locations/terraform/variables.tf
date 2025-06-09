variable "domain_name" {
  type = string
}

variable "base_path" {
  type = string
}

variable "environment" {
  type = string
}

variable "user_pool_id" {
  type = string
}

variable "lambda_runtime" {
  type    = string
  default = "nodejs20.x"
}

variable "lambda_architecture" {
  type    = string
  default = "arm64"
}

variable "lambda_timeout" {
  type    = number
  default = 10
}

