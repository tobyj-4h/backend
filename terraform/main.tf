provider "aws" {
  region = "us-east-1" # Adjust as needed
}

data "aws_region" "current" {}

module "route53" {
  source                    = "./modules/route53"
  domain_name               = var.domain_name
  hosted_zone_id            = var.hosted_zone_id
  api_gateway_domain_name   = module.api_gateway.api_gateway_domain_name
  api_gateway_zone_id       = module.api_gateway.api_gateway_zone_id
  domain_validation_options = module.acm.domain_validation_options
}

module "acm" {
  source                  = "./modules/acm"
  domain_name             = var.domain_name
  validation_record_fqdns = module.route53.validation_record_fqdns
}

module "api_gateway" {
  source          = "./modules/api_gateway"
  domain_name     = var.domain_name
  certificate_arn = module.acm.certificate_arn
}

module "auth" {
  source       = "../api/auth/terraform"
  user_pool_id = var.user_pool_id
}

module "user_api" {
  source                        = "../api/user/terraform"
  base_path                     = "user"
  domain_name                   = var.domain_name
  custom_authorizer_lambda_name = module.auth.custom_authorizer_lambda_name
  custom_authorizer_lambda_arn  = module.auth.custom_authorizer_lambda_arn
  environment                   = var.environment
}
