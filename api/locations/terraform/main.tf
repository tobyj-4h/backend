# Use the current AWS region without a variable by using data source
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# REST API for Locations
resource "aws_api_gateway_rest_api" "locations_api" {
  name        = "LocationsAPI"
  description = "API for location-related queries such as schools and districts."
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "locations_api_logs" {
  name              = "/aws/api-gateway/locations-api"
  retention_in_days = 14
}

# Deploy API Gateway for Locations
resource "aws_api_gateway_deployment" "locations_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.locations_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.location_item_resource,
      aws_api_gateway_method.get_location_item_method,
      aws_api_gateway_integration.get_location_item_lambda_integration,

      aws_api_gateway_resource.districts_resource,
      aws_api_gateway_method.get_districts_method,
      aws_api_gateway_integration.get_districts_lambda_integration,

      aws_api_gateway_resource.schools_resource,
      aws_api_gateway_method.get_schools_method,
      aws_api_gateway_integration.get_schools_lambda_integration,

      aws_api_gateway_resource.geocode_resource,
      aws_api_gateway_method.get_geocode_method,
      aws_api_gateway_integration.get_geocode_lambda_integration,

      aws_api_gateway_resource.suggestions_resource,
      aws_api_gateway_method.get_suggestions_method,
      aws_api_gateway_integration.get_suggestions_lambda_integration,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create API Gateway Stage (prod)
resource "aws_api_gateway_stage" "locations_api_stage" {
  stage_name    = "prod"
  rest_api_id   = aws_api_gateway_rest_api.locations_api.id
  deployment_id = aws_api_gateway_deployment.locations_api_deployment.id

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.locations_api_logs.arn
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

  depends_on = [aws_api_gateway_deployment.locations_api_deployment]
}

# Enable logging and metrics for the API Gateway
resource "aws_api_gateway_method_settings" "logging" {
  rest_api_id = aws_api_gateway_rest_api.locations_api.id
  stage_name  = aws_api_gateway_stage.locations_api_stage.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled    = true
    logging_level      = "INFO"
    data_trace_enabled = true
  }
}

# Create Base Path Mapping for the Custom Domain
resource "aws_api_gateway_base_path_mapping" "locations_api_mapping" {
  api_id      = aws_api_gateway_rest_api.locations_api.id
  stage_name  = aws_api_gateway_stage.locations_api_stage.stage_name
  domain_name = var.domain_name
  base_path   = var.base_path
}

# Permissions for API Gateway to invoke the authorizer Lambda function
resource "aws_lambda_permission" "locations_api_authorizer_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.locations_authorizer_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.locations_api.execution_arn}/*/GET/locations/*"
}
