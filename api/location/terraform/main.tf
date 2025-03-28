# Use the current AWS region without a variable by using data source
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_api_gateway_rest_api" "location_api" {
  name        = "LocationAPI"
  description = "API Gateway REST API for retrieving location data like school districts and schools"
}

resource "aws_cloudwatch_log_group" "location_api_gw_logs" {
  name              = "/aws/api-gateway/location-api"
  retention_in_days = 14
}

resource "aws_api_gateway_deployment" "location_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.location_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.districts_resource,
      aws_api_gateway_method.get_districts_method,
      aws_api_gateway_resource.schools_resource,
      aws_api_gateway_method.get_schools_method,
      aws_api_gateway_resource.geocode_resource,
      aws_api_gateway_method.get_geocode_method,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "location_api_stage" {
  deployment_id = aws_api_gateway_deployment.location_api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.location_api.id
  stage_name    = "prod"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.location_api_gw_logs.arn
    format = jsonencode({
      requestId    = "$context.requestId",
      ip           = "$context.identity.sourceIp",
      requestTime  = "$context.requestTime",
      httpMethod   = "$context.httpMethod",
      resourcePath = "$context.resourcePath",
      status       = "$context.status"
    })
  }

  depends_on = [aws_api_gateway_deployment.location_api_deployment]
}

resource "aws_api_gateway_method_settings" "location_all" {
  rest_api_id = aws_api_gateway_rest_api.location_api.id
  stage_name  = aws_api_gateway_stage.location_api_stage.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled    = true
    logging_level      = "INFO"
    data_trace_enabled = true
  }
}

resource "aws_api_gateway_base_path_mapping" "location_api_mapping" {
  api_id      = aws_api_gateway_rest_api.location_api.id
  stage_name  = aws_api_gateway_stage.location_api_stage.stage_name
  domain_name = var.domain_name
  base_path   = var.base_path
}

resource "aws_lambda_permission" "location_api_authorizer_permission" {
  statement_id  = "LocationAPIAllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.location_authorizer_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.location_api.execution_arn}/*/*"
}

resource "aws_api_gateway_authorizer" "location_authorizer" {
  name                             = "LocationAPIAuthorizer"
  rest_api_id                      = aws_api_gateway_rest_api.location_api.id
  authorizer_uri                   = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.location_authorizer_lambda.arn}/invocations"
  authorizer_result_ttl_in_seconds = 300
  identity_source                  = "method.request.header.Authorization"
  type                             = "TOKEN"
}
