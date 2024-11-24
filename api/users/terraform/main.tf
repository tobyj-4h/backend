# Use the current AWS region without a variable by using data source
data "aws_region" "current" {}

# Define REST API
resource "aws_api_gateway_rest_api" "users_api" {
  name        = "UserAPI"
  description = "API Gateway REST API for UserAPI"
}

# Log Group
resource "aws_cloudwatch_log_group" "user_api_gw_logs" {
  name              = "/aws/api-gateway/user-api"
  retention_in_days = 14 # Customize as needed
}

# Deploy API
resource "aws_api_gateway_deployment" "users_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.users_api.id
  description = "Deployed at ${timestamp()}"

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.preferences_resource.id,
      aws_api_gateway_method.user_preferences_get_method,
      aws_api_gateway_method.user_preferences_post_method.id,
      aws_api_gateway_method.user_preferences_options_method.id,
      aws_api_gateway_resource.associations_resource.id,
      aws_api_gateway_method.user_associations_get_method.id,
      aws_api_gateway_method.user_associations_post_method.id,
      aws_api_gateway_method.user_associations_options_method.id,
      aws_api_gateway_resource.settings_resource.id,
      aws_api_gateway_method.user_settings_get_method.id,
      aws_api_gateway_method.user_settings_post_method.id,
      aws_api_gateway_method.user_settings_options_method.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "users_api_stage" {
  deployment_id = aws_api_gateway_deployment.users_api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.users_api.id
  stage_name    = "prod"
  description   = "Deployed at ${timestamp()}"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.user_api_gw_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId",
      ip             = "$context.identity.sourceIp",
      caller         = "$context.identity.caller",
      user           = "$context.identity.user",
      requestTime    = "$context.requestTime",
      httpMethod     = "$context.httpMethod",
      resourcePath   = "$context.resourcePath",
      status         = "$context.status",
      protocol       = "$context.protocol",
      responseLength = "$context.responseLength"
    })
  }

  depends_on = [aws_api_gateway_deployment.users_api_deployment]
}

# Enable Method Settings
resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.users_api.id
  stage_name  = aws_api_gateway_stage.users_api_stage.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled    = true
    logging_level      = "INFO"
    data_trace_enabled = true
  }
}

# Create a base path mapping for the custom domain
resource "aws_api_gateway_base_path_mapping" "users_api_mapping" {
  api_id      = aws_api_gateway_rest_api.users_api.id
  stage_name  = aws_api_gateway_stage.users_api_stage.stage_name
  domain_name = var.domain_name
  base_path   = var.base_path
}

# Permissions for API Gateway to Invoke the Authorizer
resource "aws_lambda_permission" "api_gateway_authorizer_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.custom_authorizer_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.users_api.execution_arn}/*/*"
}

resource "aws_api_gateway_authorizer" "custom_authorizer" {
  name                             = "UserAPICustomAuthorizer"
  rest_api_id                      = aws_api_gateway_rest_api.users_api.id
  authorizer_uri                   = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${var.custom_authorizer_lambda_arn}/invocations"
  authorizer_result_ttl_in_seconds = 300
  identity_source                  = "method.request.header.Authorization"
  type                             = "TOKEN"
}

