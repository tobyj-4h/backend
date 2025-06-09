####################################################################################################
# Locations Authorizer Lambda
####################################################################################################

##################################################
# LAMBDA: Locations Authorizer Lambda Exec Role
##################################################
resource "aws_iam_role" "locations_authorizer_lambda_exec" {
  name = "locations_authorizer_lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

##################################################
# LAMBDA: Locations Authorizer Lambda
##################################################
resource "aws_lambda_function" "locations_authorizer_lambda" {
  function_name = "LocationsAuthorizerFunction"
  handler       = "locations-authorizer.handler"
  runtime       = var.lambda_runtime
  role          = aws_iam_role.locations_authorizer_lambda_exec.arn

  filename         = "${path.module}/../dist/locations-authorizer.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/locations-authorizer.zip")

  environment {
    variables = {
      LOG_LEVEL    = "INFO"
      USER_POOL_ID = var.user_pool_id
      REGION       = data.aws_region.current.name
    }
  }
}

##################################################
# LAMBDA: Locations Authorizer Permission
##################################################
resource "aws_lambda_permission" "allow_apigw_invoke_locations_authorizer" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.locations_authorizer_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.locations_api.execution_arn}/*/*"
}

##################################################
# LAMBDA: Locations Authorizer Lambda Log Group
##################################################
resource "aws_cloudwatch_log_group" "locations_authorizer_lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.locations_authorizer_lambda.function_name}"
  retention_in_days = 7
}

##################################################
# LAMBDA: Locations Authorizer Lambda Policy
##################################################
resource "aws_iam_policy" "locations_authorizer_lambda_policy" {
  name = "${aws_lambda_function.locations_authorizer_lambda.function_name}Policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Effect = "Allow"
      Resource = [
        aws_cloudwatch_log_group.locations_authorizer_lambda_log_group.arn,       # Restrict to specific log group
        "${aws_cloudwatch_log_group.locations_authorizer_lambda_log_group.arn}:*" # Allow access to log streams in the group
      ]
      }
    ]
  })
}

##################################################
# LAMBDA: Locations Authorizer Lambda Attach Policy
##################################################
resource "aws_iam_role_policy_attachment" "locations_authorizer_lambda_attach_policy" {
  role       = aws_iam_role.locations_authorizer_lambda_exec.name
  policy_arn = aws_iam_policy.locations_authorizer_lambda_policy.arn
}

# Define Custom Authorizer for API Gateway
resource "aws_api_gateway_authorizer" "locations_authorizer" {
  name           = "LocationsAPIAuthorizer"
  rest_api_id    = aws_api_gateway_rest_api.locations_api.id
  authorizer_uri = aws_lambda_function.locations_authorizer_lambda.invoke_arn
  # authorizer_credentials           = aws_iam_role.location_authorizer_lambda_exec.arn
  authorizer_result_ttl_in_seconds = 300
  identity_source                  = "method.request.header.Authorization"
  type                             = "TOKEN"
}
