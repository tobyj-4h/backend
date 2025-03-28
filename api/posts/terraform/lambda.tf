resource "aws_iam_role" "posts_lambda_exec" {
  name = "posts_api_lambda_exec_role"

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

resource "aws_iam_role_policy_attachment" "posts_lambda_logs" {
  role       = aws_iam_role.posts_lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# DynamoDB access policy for the Lambda functions
resource "aws_iam_policy" "posts_dynamodb_access" {
  name = "PostsDynamoDBAccessPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query",
        "dynamodb:Scan"
      ]
      Effect   = "Allow"
      Resource = aws_dynamodb_table.posts.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "posts_dynamodb_policy_attachment" {
  role       = aws_iam_role.posts_lambda_exec.name
  policy_arn = aws_iam_policy.posts_dynamodb_access.arn
}

##################################################
# LAMBDA: Posts Get Items
##################################################
resource "aws_lambda_function" "posts_get_items_lambda" {
  function_name = "PostsGetItemsFunction"
  handler       = "posts-get-items.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.posts_lambda_exec.arn

  filename         = "${path.module}/../dist/posts-get-items.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/posts-get-items.zip")

  environment {
    variables = {
      POSTS_TABLE    = aws_dynamodb_table.posts.id
      REQUIRED_SCOPE = "https://api.dev.fourhorizonsed.com/beehive.post.read"
    }
  }
}

##################################################
# LAMBDA: Posts Get Items Permission
##################################################
resource "aws_lambda_permission" "api_gateway_posts_get_items_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.posts_get_items_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.posts_api.execution_arn}/*/*"
}

##################################################
# LAMBDA: Posts Get Items Log Group
##################################################
resource "aws_cloudwatch_log_group" "posts_get_items_log_group" {
  name              = "/aws/lambda/PostsGetItemsFunction"
  retention_in_days = 7
}

##################################################
# LAMBDA: Posts Get Items Policy
##################################################
resource "aws_iam_policy" "posts_get_items_lambda_policy" {
  name = "PostsGetItemsPolicy"
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
        aws_cloudwatch_log_group.posts_get_items_log_group.arn,
        "${aws_cloudwatch_log_group.posts_get_items_log_group.arn}:*"
      ]
    }]
  })
}

##################################################
# LAMBDA: Posts Get Items Attach Policy
##################################################
resource "aws_iam_role_policy_attachment" "posts_get_items_lambda_attach_policy" {
  role       = aws_iam_role.posts_lambda_exec.name
  policy_arn = aws_iam_policy.posts_get_items_lambda_policy.arn
}


##################################################
# LAMBDA: Posts Create Item
##################################################
resource "aws_lambda_function" "posts_create_item_lambda" {
  function_name = "PostsCreateItemFunction"
  handler       = "posts-create-item.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.posts_lambda_exec.arn

  filename         = "${path.module}/../dist/posts-create-item.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/posts-create-item.zip")

  environment {
    variables = {
      POSTS_TABLE    = aws_dynamodb_table.posts.id
      REQUIRED_SCOPE = "https://api.dev.fourhorizonsed.com/beehive.post.write"
    }
  }
}

##################################################
# LAMBDA: Posts Create Item Permission
##################################################
resource "aws_lambda_permission" "api_gateway_posts_create_item_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.posts_create_item_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.posts_api.execution_arn}/*/*"
}

##################################################
# LAMBDA: Posts Create Item Log Group
##################################################
resource "aws_cloudwatch_log_group" "posts_create_item_log_group" {
  name              = "/aws/lambda/PostsCreateItemFunction"
  retention_in_days = 7
}

##################################################
# LAMBDA: Posts Create Item Policy
##################################################
resource "aws_iam_policy" "posts_create_item_lambda_policy" {
  name = "PostsCreatePolicy"
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
        aws_cloudwatch_log_group.posts_create_item_log_group.arn,
        "${aws_cloudwatch_log_group.posts_create_item_log_group.arn}:*"
      ]
    }]
  })
}

##################################################
# LAMBDA: Posts Create Item Attach Policy
##################################################
resource "aws_iam_role_policy_attachment" "posts_create_item_lambda_attach_policy" {
  role       = aws_iam_role.posts_lambda_exec.name
  policy_arn = aws_iam_policy.posts_create_item_lambda_policy.arn
}

##################################################
# LAMBDA: Posts Get Item
##################################################
resource "aws_lambda_function" "posts_get_item_lambda" {
  function_name = "PostsGetItemFunction"
  handler       = "posts-get-item.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.posts_lambda_exec.arn

  filename         = "${path.module}/../dist/posts-get-item.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/posts-get-item.zip")

  environment {
    variables = {
      POSTS_TABLE    = aws_dynamodb_table.posts.id
      REQUIRED_SCOPE = "https://api.dev.fourhorizonsed.com/beehive.post.read"
    }
  }
}

##################################################
# LAMBDA: Posts Get Item Permission
##################################################
resource "aws_lambda_permission" "api_gateway_posts_get_item_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.posts_get_item_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.posts_api.execution_arn}/*/*"
}

##################################################
# LAMBDA: Posts Get Item  Log Group
##################################################
resource "aws_cloudwatch_log_group" "posts_get_item_log_group" {
  name              = "/aws/lambda/PostsGetItemFunction"
  retention_in_days = 7
}

##################################################
# LAMBDA: Posts Get Item Policy
##################################################
resource "aws_iam_policy" "posts_get_item_lambda_policy" {
  name = "PostsGetItemPolicy"
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
        aws_cloudwatch_log_group.posts_get_item_log_group.arn,
        "${aws_cloudwatch_log_group.posts_get_item_log_group.arn}:*"
      ]
    }]
  })
}

##################################################
# LAMBDA: Posts Get Item Attach Policy
##################################################
resource "aws_iam_role_policy_attachment" "posts_get_item_lambda_attach_policy" {
  role       = aws_iam_role.posts_lambda_exec.name
  policy_arn = aws_iam_policy.posts_get_item_lambda_policy.arn
}

##################################################
# LAMBDA: Posts Update Item
##################################################
resource "aws_lambda_function" "posts_update_item_lambda" {
  function_name = "PostsUpdateItemFunction"
  handler       = "posts-update-item.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.posts_lambda_exec.arn

  filename         = "${path.module}/../dist/posts-update-item.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/posts-update-item.zip")

  environment {
    variables = {
      POSTS_TABLE    = aws_dynamodb_table.posts.id
      REQUIRED_SCOPE = "https://api.dev.fourhorizonsed.com/beehive.post.write"
    }
  }
}

##################################################
# LAMBDA: Posts Update Item Permission
##################################################
resource "aws_lambda_permission" "api_gateway_posts_update_item_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.posts_update_item_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.posts_api.execution_arn}/*/*"
}

##################################################
# LAMBDA: Posts Update Item Log Group
##################################################
resource "aws_cloudwatch_log_group" "posts_update_item_log_group" {
  name              = "/aws/lambda/PostsUpdateItemFunction"
  retention_in_days = 7
}

##################################################
# LAMBDA: Posts Update Item Policy
##################################################
resource "aws_iam_policy" "posts_update_item_lambda_policy" {
  name = "PostsUpdateItemPolicy"
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
        aws_cloudwatch_log_group.posts_update_item_log_group.arn,
        "${aws_cloudwatch_log_group.posts_update_item_log_group.arn}:*"
      ]
    }]
  })
}

##################################################
# LAMBDA: Posts Update Item Attach Policy
##################################################
resource "aws_iam_role_policy_attachment" "posts_update_item_lambda_attach_policy" {
  role       = aws_iam_role.posts_lambda_exec.name
  policy_arn = aws_iam_policy.posts_update_item_lambda_policy.arn
}

##################################################
# LAMBDA: Posts Delete Item
##################################################
resource "aws_lambda_function" "posts_delete_item_lambda" {
  function_name = "PostsDeleteItemFunction"
  handler       = "posts-delete-item.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.posts_lambda_exec.arn

  filename         = "${path.module}/../dist/posts-delete-item.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/posts-delete-item.zip")

  environment {
    variables = {
      POSTS_TABLE    = aws_dynamodb_table.posts.id
      REQUIRED_SCOPE = "https://api.dev.fourhorizonsed.com/beehive.post.admin"
    }
  }
}

##################################################
# LAMBDA: Posts Delete Item Permission
##################################################
resource "aws_lambda_permission" "api_gateway_posts_delete_item_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.posts_delete_item_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.posts_api.execution_arn}/*/*"
}

##################################################
# LAMBDA: Posts Delete Item Log Group
##################################################
resource "aws_cloudwatch_log_group" "posts_delete_item_log_group" {
  name              = "/aws/lambda/PostsDeleteItemFunction"
  retention_in_days = 7
}

##################################################
# LAMBDA: Posts Delete Item Policy
##################################################
resource "aws_iam_policy" "posts_delete_item_lambda_policy" {
  name = "PostsDeletePolicy"
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
        aws_cloudwatch_log_group.posts_delete_item_log_group.arn,
        "${aws_cloudwatch_log_group.posts_delete_item_log_group.arn}:*"
      ]
    }]
  })
}

##################################################
# LAMBDA: Posts Delete Item Attach Policy
##################################################
resource "aws_iam_role_policy_attachment" "posts_delete_item_lambda_attach_policy" {
  role       = aws_iam_role.posts_lambda_exec.name
  policy_arn = aws_iam_policy.posts_delete_item_lambda_policy.arn
}


##################################################
# LAMBDA: Posts Authorizer Lambda Exec Role
##################################################
resource "aws_iam_role" "posts_authorizer_lambda_exec" {
  name = "posts_authorizer_lambda_exec_role"

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
# LAMBDA: Posts Authorizer Lambda
##################################################
resource "aws_lambda_function" "posts_authorizer_lambda" {
  function_name = "PostsAuthorizerFunction"
  handler       = "posts-authorizer.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.posts_authorizer_lambda_exec.arn

  filename         = "${path.module}/../dist/posts-authorizer.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/posts-authorizer.zip")

  environment {
    variables = {
      LOG_LEVEL    = "INFO"
      USER_POOL_ID = var.user_pool_id
      REGION       = data.aws_region.current.name
    }
  }
}

##################################################
# LAMBDA: Posts Authorizer Lambda Log Group
##################################################
resource "aws_cloudwatch_log_group" "posts_authorizer_lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.posts_authorizer_lambda.function_name}"
  retention_in_days = 7
}

##################################################
# LAMBDA: Posts Authorizer Lambda Policy
##################################################
resource "aws_iam_policy" "posts_authorizer_lambda_policy" {
  name = "${aws_lambda_function.posts_authorizer_lambda.function_name}Policy"
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
        aws_cloudwatch_log_group.posts_authorizer_lambda_log_group.arn,       # Restrict to specific log group
        "${aws_cloudwatch_log_group.posts_authorizer_lambda_log_group.arn}:*" # Allow access to log streams in the group
      ]
      }
    ]
  })
}

##################################################
# LAMBDA: Posts Authorizer Lambda Attach Policy
##################################################
resource "aws_iam_role_policy_attachment" "posts_authorizer_lambda_attach_policy" {
  role       = aws_iam_role.posts_authorizer_lambda_exec.name
  policy_arn = aws_iam_policy.posts_authorizer_lambda_policy.arn
}
