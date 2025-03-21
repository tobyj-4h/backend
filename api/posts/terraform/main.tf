# Use the current AWS region
data "aws_region" "current" {}

# Define REST API for Posts
resource "aws_api_gateway_rest_api" "posts_api" {
  name        = "PostsAPI"
  description = "API Gateway REST API for handling posts creation, retrieval, updates, and deletion"
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "posts_api_gw_logs" {
  name              = "/aws/api-gateway/posts-api"
  retention_in_days = 14 # Customize as needed
}

# Deploy API Gateway for Posts
resource "aws_api_gateway_deployment" "posts_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.posts_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.posts_item_resource,
      aws_api_gateway_method.posts_get_items_method,
      aws_api_gateway_method.posts_create_item_method,
      aws_api_gateway_method.posts_get_item_method,
      aws_api_gateway_method.posts_item_put_method,
      aws_api_gateway_method.posts_item_delete_method
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create API Gateway Stage (prod)
resource "aws_api_gateway_stage" "posts_api_stage" {
  deployment_id = aws_api_gateway_deployment.posts_api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.posts_api.id
  stage_name    = "prod"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.posts_api_gw_logs.arn
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

  depends_on = [aws_api_gateway_deployment.posts_api_deployment]
}

# Enable Detailed Logging & Metrics for All API Methods
resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.posts_api.id
  stage_name  = aws_api_gateway_stage.posts_api_stage.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled    = true
    logging_level      = "INFO"
    data_trace_enabled = true
  }
}

# Create Base Path Mapping for the Custom Domain
resource "aws_api_gateway_base_path_mapping" "posts_api_mapping" {
  api_id      = aws_api_gateway_rest_api.posts_api.id
  stage_name  = aws_api_gateway_stage.posts_api_stage.stage_name
  domain_name = var.domain_name
  base_path   = var.base_path
}

# Permissions for API Gateway to Invoke the Authorizer
resource "aws_lambda_permission" "api_gateway_authorizer_permission" {
  statement_id  = "PostsAPIAllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.custom_authorizer_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.posts_api.execution_arn}/*/*"
}

# Define Custom Authorizer for API Gateway
resource "aws_api_gateway_authorizer" "custom_authorizer" {
  name                             = "PostsAPICustomAuthorizer"
  rest_api_id                      = aws_api_gateway_rest_api.posts_api.id
  authorizer_uri                   = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${var.custom_authorizer_lambda_arn}/invocations"
  authorizer_result_ttl_in_seconds = 300
  identity_source                  = "method.request.header.Authorization"
  type                             = "TOKEN"
}
