# Use the current AWS region
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Define REST API for Post Interactions
resource "aws_api_gateway_rest_api" "interactions_api" {
  name        = "PostInteractionsAPI"
  description = "API Gateway REST API for handling post interactions (reactions, comments, favorites, views)"
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "interactions_api_gw_logs" {
  name              = "/aws/api-gateway/interactions-api"
  retention_in_days = 14 # Customize as needed`
}

# Deploy API Gateway for Interactions
resource "aws_api_gateway_deployment" "interactions_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.interactions_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.post_resource,
      aws_api_gateway_resource.post_reactions_resource,
      aws_api_gateway_resource.post_comments_resource,
      aws_api_gateway_resource.individual_comment_resource,
      aws_api_gateway_resource.comment_replies_resource,
      aws_api_gateway_resource.comment_reactions_resource,
      aws_api_gateway_resource.post_favorites_resource,
      aws_api_gateway_resource.post_views_resource,
      aws_api_gateway_method.post_reactions_method,
      aws_api_gateway_method.put_reactions_method,
      aws_api_gateway_method.delete_reactions_method,
      aws_api_gateway_method.get_reactions_method,
      aws_api_gateway_method.comment_post_method,
      aws_api_gateway_method.get_comments_method,
      aws_api_gateway_method.reply_to_comment_method,
      aws_api_gateway_method.comment_reactions_post_method,
      aws_api_gateway_method.comment_reactions_put_method,
      aws_api_gateway_method.comment_reactions_delete_method,
      aws_api_gateway_method.comment_reactions_get_method,
      aws_api_gateway_method.favorite_post_method,
      aws_api_gateway_method.unfavorite_post_method,
      aws_api_gateway_method.view_post_method,
      aws_api_gateway_integration.post_reactions_lambda_integration,
      aws_api_gateway_integration.put_reactions_lambda_integration,
      aws_api_gateway_integration.delete_reactions_lambda_integration,
      aws_api_gateway_integration.get_reactions_lambda_integration,
      aws_api_gateway_integration.comment_post_lambda_integration,
      aws_api_gateway_integration.get_comments_lambda_integration,
      aws_api_gateway_integration.reply_to_comment_lambda_integration,
      aws_api_gateway_integration.comment_reactions_post_lambda_integration,
      aws_api_gateway_integration.comment_reactions_put_lambda_integration,
      aws_api_gateway_integration.comment_reactions_delete_lambda_integration,
      aws_api_gateway_integration.comment_reactions_get_lambda_integration,
      aws_api_gateway_integration.favorite_post_lambda_integration,
      aws_api_gateway_integration.unfavorite_post_lambda_integration,
      aws_api_gateway_integration.view_post_lambda_integration,
      aws_api_gateway_authorizer.custom_authorizer
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create API Gateway Stage (prod)
resource "aws_api_gateway_stage" "interactions_api_stage" {
  deployment_id = aws_api_gateway_deployment.interactions_api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.interactions_api.id
  stage_name    = "prod"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.interactions_api_gw_logs.arn
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

  depends_on = [aws_api_gateway_deployment.interactions_api_deployment]
}

# Enable Detailed Logging & Metrics for All API Methods
resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.interactions_api.id
  stage_name  = aws_api_gateway_stage.interactions_api_stage.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled    = true
    logging_level      = "INFO"
    data_trace_enabled = true
  }
}

# Create Base Path Mapping for the Custom Domain
resource "aws_api_gateway_base_path_mapping" "interactions_api_mapping" {
  api_id      = aws_api_gateway_rest_api.interactions_api.id
  stage_name  = aws_api_gateway_stage.interactions_api_stage.stage_name
  domain_name = var.domain_name
  base_path   = var.base_path
}

# Permissions for API Gateway to Invoke the Authorizer
resource "aws_lambda_permission" "api_gateway_authorizer_permission" {
  statement_id  = "InteractionsAPIAllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_interactions_authorizer_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.interactions_api.execution_arn}/*/*"
}

# Define Custom Authorizer for API Gateway
resource "aws_api_gateway_authorizer" "custom_authorizer" {
  name                             = "InteractionsAPICustomAuthorizer"
  rest_api_id                      = aws_api_gateway_rest_api.interactions_api.id
  authorizer_uri                   = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.post_interactions_authorizer_lambda.arn}/invocations"
  authorizer_result_ttl_in_seconds = 300
  identity_source                  = "method.request.header.Authorization"
  type                             = "TOKEN"
}
