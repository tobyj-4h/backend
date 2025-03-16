# Use the current AWS region without a variable by using data source
data "aws_region" "current" {}

# Define REST API
resource "aws_api_gateway_rest_api" "schools_api" {
  name        = "SchoolsAPI"
  description = "API Gateway REST API for SchoolsAPI"
}

# Log Group
resource "aws_cloudwatch_log_group" "schools_api_gw_logs" {
  name              = "/aws/api-gateway/schools-api"
  retention_in_days = 14 # Customize as needed
}

# Deploy API
resource "aws_api_gateway_deployment" "schools_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.schools_api.id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_method.root_options_method,
      aws_api_gateway_method.get_school_by_id_method,
      aws_api_gateway_method.get_schools_by_district_method,
      aws_api_gateway_method.school_id_options_method,
      aws_api_gateway_method.get_schools_nearby_method,
      aws_api_gateway_method.nearby_options_method,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "schools_api_stage" {
  deployment_id = aws_api_gateway_deployment.schools_api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.schools_api.id
  stage_name    = "prod"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.schools_api_gw_logs.arn
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

  depends_on = [aws_api_gateway_deployment.schools_api_deployment]
}

# Enable Method Settings
resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.schools_api.id
  stage_name  = aws_api_gateway_stage.schools_api_stage.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled    = true
    logging_level      = "INFO"
    data_trace_enabled = true
  }
}

# Create a base path mapping for the custom domain
resource "aws_api_gateway_base_path_mapping" "schools_api_mapping" {
  api_id      = aws_api_gateway_rest_api.schools_api.id
  stage_name  = aws_api_gateway_stage.schools_api_stage.stage_name
  domain_name = var.domain_name
  base_path   = var.base_path
}

# Permissions for API Gateway to Invoke the Authorizer
resource "aws_lambda_permission" "api_gateway_authorizer_permission" {
  statement_id  = "AllowExecutionFromSchoolsAPIAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.custom_authorizer_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.schools_api.execution_arn}/*/*"
}

# Custom Authorizer
resource "aws_api_gateway_authorizer" "custom_authorizer" {
  name                             = "SchoolsAPICustomAuthorizer"
  rest_api_id                      = aws_api_gateway_rest_api.schools_api.id
  authorizer_uri                   = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${var.custom_authorizer_lambda_arn}/invocations"
  authorizer_result_ttl_in_seconds = 300
  identity_source                  = "method.request.header.Authorization"
  type                             = "TOKEN"
}



# ##################################################
# # API Gateway: Schools Nearby Resource ("/nearby")
# ##################################################
# resource "aws_api_gateway_resource" "schools_nearby_resource" {
#   rest_api_id = aws_api_gateway_rest_api.schools_api.id
#   parent_id   = aws_api_gateway_rest_api.schools_api.root_resource_id
#   path_part   = "nearby"
# }

# ##################################################
# # API Gateway: OPTIONS Method for /nearby
# ##################################################
# resource "aws_api_gateway_method" "schools_get_nearby_options_method" {
#   rest_api_id   = aws_api_gateway_rest_api.schools_api.id
#   resource_id   = aws_api_gateway_resource.schools_nearby_resource.id
#   http_method   = "OPTIONS"
#   authorization = "NONE"
# }

# resource "aws_api_gateway_integration" "schools_get_nearby_options_integration" {
#   rest_api_id = aws_api_gateway_rest_api.schools_api.id
#   resource_id = aws_api_gateway_resource.schools_nearby_resource.id
#   http_method = aws_api_gateway_method.schools_get_nearby_options_method.http_method
#   type        = "MOCK"

#   request_templates = {
#     "application/json" = "{\"statusCode\": 200}"
#   }
# }

# resource "aws_api_gateway_method_response" "schools_get_nearby_options_response" {
#   rest_api_id = aws_api_gateway_rest_api.schools_api.id
#   resource_id = aws_api_gateway_resource.schools_nearby_resource.id
#   http_method = aws_api_gateway_method.schools_get_nearby_options_method.http_method
#   status_code = "200"

#   response_parameters = {
#     "method.response.header.Access-Control-Allow-Origin"  = true
#     "method.response.header.Access-Control-Allow-Methods" = true
#     "method.response.header.Access-Control-Allow-Headers" = true
#   }
# }

# ##################################################
# # API Gateway: GET Method for /nearby
# ##################################################
# resource "aws_api_gateway_method" "schools_get_nearby_method" {
#   rest_api_id   = aws_api_gateway_rest_api.schools_api.id
#   resource_id   = aws_api_gateway_resource.schools_nearby_resource.id
#   http_method   = "GET"
#   authorization = "NONE" # Assuming no authentication is required, can be changed as needed
# }

# resource "aws_api_gateway_integration" "schools_get_nearby_lambda_integration" {
#   rest_api_id             = aws_api_gateway_rest_api.schools_api.id
#   resource_id             = aws_api_gateway_resource.schools_nearby_resource.id
#   http_method             = aws_api_gateway_method.schools_get_nearby_method.http_method
#   integration_http_method = "POST"
#   type                    = "AWS_PROXY"
#   uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.schools_get_nearby_lambda.arn}/invocations"
# }

# ##################################################
# # Lambda: Schools Get Nearby (Get schools based on lat/lng) - Python 3.13
# ##################################################
# resource "aws_lambda_function" "schools_get_nearby_lambda" {
#   function_name = "SchoolsGetNearbyFunction"
#   handler       = "schools-get-nearby.handler"
#   runtime       = "python3.13"
#   role          = aws_iam_role.lambda_exec.arn

#   filename         = "${path.module}/../dist/schools-get-nearby.zip"
#   source_code_hash = filebase64sha256("${path.module}/../dist/schools-get-nearby.zip")

#   environment {
#     variables = {
#       TABLE_NAME              = aws_dynamodb_table.schools.name
#       SAGEMAKER_ENDPOINT_NAME = aws_sagemaker_endpoint.school_district_endpoint_v1_0_9.name
#     }
#   }

#   tracing_config {
#     mode = "Active"
#   }
# }

# resource "aws_lambda_permission" "schools_get_nearby_invoke_permission" {
#   statement_id  = "AllowExecutionFromAPIGateway"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.schools_get_nearby_lambda.function_name
#   principal     = "apigateway.amazonaws.com"
#   source_arn    = "${aws_api_gateway_rest_api.schools_api.execution_arn}/*/*"
# }



