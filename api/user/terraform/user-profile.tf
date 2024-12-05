##################################################
# DynamoDB: UserProfile Table
##################################################
resource "aws_dynamodb_table" "user_profile" {
  name         = "UserProfile"
  billing_mode = "PAY_PER_REQUEST" # On-demand pricing for cost efficiency
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  attribute {
    name = "email"
    type = "S"
  }

  global_secondary_index {
    name            = "GSI1"
    hash_key        = "email"
    projection_type = "ALL"
  }

  tags = {
    Environment = var.environment
  }
}

##################################################
# API Gateway: Profile Resource
##################################################
resource "aws_api_gateway_resource" "profile_resource" {
  rest_api_id = aws_api_gateway_rest_api.user_api.id
  parent_id   = aws_api_gateway_rest_api.user_api.root_resource_id
  path_part   = "profile"
}

# Define the OPTIONS method
resource "aws_api_gateway_method" "user_profile_options_method" {
  rest_api_id   = aws_api_gateway_rest_api.user_api.id
  resource_id   = aws_api_gateway_resource.profile_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "user_profile_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.user_api.id
  resource_id = aws_api_gateway_resource.profile_resource.id
  http_method = aws_api_gateway_method.user_profile_options_method.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "profile_options_response" {
  rest_api_id = aws_api_gateway_rest_api.user_api.id
  resource_id = aws_api_gateway_resource.profile_resource.id
  http_method = aws_api_gateway_method.user_profile_options_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Headers" = true
  }
}

##################################################
# Lambda: User Profile Get 
##################################################
resource "aws_cloudwatch_log_group" "user_profile_get_lambda_log_group" {
  name              = "/aws/lambda/UserProfileGetFunction"
  retention_in_days = 7
}

resource "aws_iam_policy" "user_profile_get_lambda_policy" {
  name = "UserProfileGetLambdaPolicy"
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
        aws_cloudwatch_log_group.user_profile_get_lambda_log_group.arn,       # Restrict to specific log group
        "${aws_cloudwatch_log_group.user_profile_get_lambda_log_group.arn}:*" # Allow access to log streams in the group
      ]
      }, {
      Effect = "Allow",
      Action = [
        "dynamodb:GetItem",
        "dynamodb:Query",
        "dynamodb:Scan"
      ],
      Resource = "${aws_dynamodb_table.user_profile.arn}"
    }]
  })
}

resource "aws_lambda_function" "user_profile_get_lambda" {
  function_name = "UserProfileGetFunction"
  handler       = "user-profile-get.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_exec.arn

  filename         = "${path.module}/../dist/user-profile-get.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/user-profile-get.zip")

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.user_profile.name
    }
  }

  tracing_config {
    mode = "Active"
  }
}

resource "aws_lambda_permission" "allow_cognito_user_profile_get" {
  statement_id  = "AllowExecutionFromCognito"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.user_profile_get_lambda.function_name
  principal     = "cognito-idp.amazonaws.com"
}

resource "aws_iam_role_policy_attachment" "user_profile_get_lambda_attach_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.user_profile_get_lambda_policy.arn
}

##################################################
# Api Gateway: User Profile Get 
##################################################
resource "aws_api_gateway_method" "user_profile_get_method" {
  rest_api_id   = aws_api_gateway_rest_api.user_api.id
  resource_id   = aws_api_gateway_resource.profile_resource.id
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id

  # Enable CORS for this method
  api_key_required = false
}

resource "aws_api_gateway_integration" "user_profile_get_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.user_api.id
  resource_id             = aws_api_gateway_resource.profile_resource.id
  http_method             = aws_api_gateway_method.user_profile_get_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.user_profile_get_lambda.arn}/invocations"
}

resource "aws_lambda_permission" "user_profile_get_invoke_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.user_profile_get_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.user_api.execution_arn}/*/*"
}

##################################################
# Lambda: User Profile Put 
##################################################
resource "aws_cloudwatch_log_group" "user_profile_put_lambda_log_group" {
  name              = "/aws/lambda/UserProfilePutFunction"
  retention_in_days = 7
}

resource "aws_iam_policy" "user_profile_put_lambda_policy" {
  name = "UserProfilePutLambdaPolicy"
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
        aws_cloudwatch_log_group.user_profile_put_lambda_log_group.arn,       # Restrict to specific log group
        "${aws_cloudwatch_log_group.user_profile_put_lambda_log_group.arn}:*" # Allow access to log streams in the group
      ]
      },
      {
        Effect   = "Allow",
        Action   = "dynamodb:PutItem",
        Resource = "${aws_dynamodb_table.user_profile.arn}"
      }
    ]
  })
}

resource "aws_lambda_function" "user_profile_put_lambda" {
  function_name = "UserProfilePutFunction"
  handler       = "user-profile-put.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_exec.arn

  filename         = "${path.module}/../dist/user-profile-put.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/user-profile-put.zip")

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.user_profile.name
    }
  }

  tracing_config {
    mode = "Active"
  }
}

resource "aws_lambda_permission" "allow_cognito_user_profile_put" {
  statement_id  = "AllowExecutionFromCognito"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.user_profile_put_lambda.function_name
  principal     = "cognito-idp.amazonaws.com"
}

resource "aws_iam_role_policy_attachment" "user_profile_put_lambda_attach_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.user_profile_put_lambda_policy.arn
}

##################################################
# Api Gateway: User Profile Put
##################################################
resource "aws_api_gateway_method" "user_profile_put_method" {
  rest_api_id   = aws_api_gateway_rest_api.user_api.id
  resource_id   = aws_api_gateway_resource.profile_resource.id
  http_method   = "PUT"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id

  # Enable CORS for this method
  api_key_required = false
}

resource "aws_api_gateway_integration" "user_profile_put_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.user_api.id
  resource_id             = aws_api_gateway_resource.profile_resource.id
  http_method             = aws_api_gateway_method.user_profile_put_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.user_profile_put_lambda.arn}/invocations"
}

resource "aws_lambda_permission" "user_profile_put_invoke_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.user_profile_put_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.user_api.execution_arn}/*/*"
}
