resource "aws_iam_role" "lambda_exec" {
  name = "interactions_api_lambda_exec_role"

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

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

##################################################
# DynamoDB Access Policy
##################################################
resource "aws_iam_policy" "dynamodb_access_policy" {
  name = "interactions_dynamodb_access_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:DeleteItem",
        "dynamodb:UpdateItem",
        "dynamodb:Query",
        "dynamodb:Scan"
      ]
      Effect = "Allow"
      Resource = [
        aws_dynamodb_table.post_events.arn,
        aws_dynamodb_table.post_reactions.arn,
        aws_dynamodb_table.post_user_favorites.arn,
        aws_dynamodb_table.post_view_counters.arn,
        aws_dynamodb_table.post_views.arn
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "dynamodb_access_attachment" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.dynamodb_access_policy.arn
}

##################################################
# LAMBDA: Reaction Post
##################################################
resource "aws_lambda_function" "reaction_post_lambda" {
  function_name = "ReactionPostFunction"
  handler       = "react-to-post.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_exec.arn

  filename         = "${path.module}/../dist/react-to-post.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/react-to-post.zip")

  environment {
    variables = {
      REACTIONS_TABLE = aws_dynamodb_table.post_reactions.id,
      EVENTS_TABLE    = aws_dynamodb_table.post_events.id,
      ENVIRONMENT     = var.environment
    }
  }
}

##################################################
# LAMBDA: Reaction Post Permission
##################################################
resource "aws_lambda_permission" "api_gateway_reaction_post_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.reaction_post_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.interactions_api.execution_arn}/*/*"
}

##################################################
# LAMBDA: Reaction Post Log Group
##################################################
resource "aws_cloudwatch_log_group" "reaction_post_log_group" {
  name              = "/aws/lambda/ReactionPostFunction"
  retention_in_days = 7
}

##################################################
# LAMBDA: Reaction Post Policy
##################################################
resource "aws_iam_policy" "reaction_post_lambda_policy" {
  name = "ReactionPostPolicy"
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
        aws_cloudwatch_log_group.reaction_post_log_group.arn,
        "${aws_cloudwatch_log_group.reaction_post_log_group.arn}:*"
      ]
    }]
  })
}

##################################################
# LAMBDA: Reaction Post Attach Policy
##################################################
resource "aws_iam_role_policy_attachment" "reaction_post_lambda_attach_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.reaction_post_lambda_policy.arn
}

##################################################
# LAMBDA: Remove Reaction Post
##################################################
resource "aws_lambda_function" "remove_reaction_post_lambda" {
  function_name = "RemoveReactionPostFunction"
  handler       = "remove-reaction-from-post.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_exec.arn

  filename         = "${path.module}/../dist/remove-reaction-from-post.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/remove-reaction-from-post.zip")

  environment {
    variables = {
      REACTIONS_TABLE = aws_dynamodb_table.post_reactions.id,
      EVENTS_TABLE    = aws_dynamodb_table.post_events.id,
      ENVIRONMENT     = var.environment
    }
  }
}

##################################################
# LAMBDA: Remove Reaction Post Permission
##################################################
resource "aws_lambda_permission" "api_gateway_remove_reaction_post_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.remove_reaction_post_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.interactions_api.execution_arn}/*/*"
}

##################################################
# LAMBDA: Remove Reaction Post Log Group
##################################################
resource "aws_cloudwatch_log_group" "remove_reaction_post_log_group" {
  name              = "/aws/lambda/RemoveReactionPostFunction"
  retention_in_days = 7
}

##################################################
# LAMBDA: Remove Reaction Post Policy
##################################################
resource "aws_iam_policy" "remove_reaction_post_lambda_policy" {
  name = "RemoveReactionPostPolicy"
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
        aws_cloudwatch_log_group.remove_reaction_post_log_group.arn,
        "${aws_cloudwatch_log_group.remove_reaction_post_log_group.arn}:*"
      ]
    }]
  })
}

##################################################
# LAMBDA: Remove Reaction Post Attach Policy
##################################################
resource "aws_iam_role_policy_attachment" "remove_reaction_post_lambda_attach_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.remove_reaction_post_lambda_policy.arn
}

##################################################
# LAMBDA: Comment Post
##################################################
resource "aws_lambda_function" "comment_post_lambda" {
  function_name = "CommentPostFunction"
  handler       = "comment-on-post.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_exec.arn

  filename         = "${path.module}/../dist/comment-on-post.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/comment-on-post.zip")

  environment {
    variables = {
      EVENTS_TABLE   = aws_dynamodb_table.post_events.id,
      COMMENTS_TABLE = aws_dynamodb_table.post_comments.id,
      ENVIRONMENT    = var.environment
    }
  }
}

##################################################
# LAMBDA: Comment Post Permission
##################################################
resource "aws_lambda_permission" "api_gateway_comment_post_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.comment_post_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.interactions_api.execution_arn}/*/*"
}

##################################################
# LAMBDA: Comment Post Log Group
##################################################
resource "aws_cloudwatch_log_group" "comment_post_log_group" {
  name              = "/aws/lambda/CommentPostFunction"
  retention_in_days = 7
}

##################################################
# LAMBDA: Comment Post Policy
##################################################
resource "aws_iam_policy" "comment_post_lambda_policy" {
  name = "CommentPostPolicy"
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
        aws_cloudwatch_log_group.comment_post_log_group.arn,
        "${aws_cloudwatch_log_group.comment_post_log_group.arn}:*"
      ]
    }]
  })
}

##################################################
# LAMBDA: Comment Post Attach Policy
##################################################
resource "aws_iam_role_policy_attachment" "comment_post_lambda_attach_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.comment_post_lambda_policy.arn
}

##################################################
# LAMBDA: Favorite Post
##################################################
resource "aws_lambda_function" "favorite_post_lambda" {
  function_name = "FavoritePostFunction"
  handler       = "favorite-post.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_exec.arn

  filename         = "${path.module}/../dist/favorite-post.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/favorite-post.zip")

  environment {
    variables = {
      FAVORITES_TABLE = aws_dynamodb_table.post_user_favorites.id,
      EVENTS_TABLE    = aws_dynamodb_table.post_events.id,
      ENVIRONMENT     = var.environment
    }
  }
}

##################################################
# LAMBDA: Favorite Post Permission
##################################################
resource "aws_lambda_permission" "api_gateway_favorite_post_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.favorite_post_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.interactions_api.execution_arn}/*/*"
}

##################################################
# LAMBDA: Favorite Post Log Group
##################################################
resource "aws_cloudwatch_log_group" "favorite_post_log_group" {
  name              = "/aws/lambda/FavoritePostFunction"
  retention_in_days = 7
}

##################################################
# LAMBDA: Favorite Post Policy
##################################################
resource "aws_iam_policy" "favorite_post_lambda_policy" {
  name = "FavoritePostPolicy"
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
        aws_cloudwatch_log_group.favorite_post_log_group.arn,
        "${aws_cloudwatch_log_group.favorite_post_log_group.arn}:*"
      ]
    }]
  })
}

##################################################
# LAMBDA: Favorite Post Attach Policy
##################################################
resource "aws_iam_role_policy_attachment" "favorite_post_lambda_attach_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.favorite_post_lambda_policy.arn
}

##################################################
# LAMBDA: Unfavorite Post
##################################################
resource "aws_lambda_function" "unfavorite_post_lambda" {
  function_name = "UnfavoritePostFunction"
  handler       = "unfavorite-post.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_exec.arn

  filename         = "${path.module}/../dist/unfavorite-post.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/unfavorite-post.zip")

  environment {
    variables = {
      FAVORITES_TABLE = aws_dynamodb_table.post_user_favorites.id,
      EVENTS_TABLE    = aws_dynamodb_table.post_events.id,
      ENVIRONMENT     = var.environment
    }
  }
}

##################################################
# LAMBDA: Unfavorite Post Permission
##################################################
resource "aws_lambda_permission" "api_gateway_unfavorite_post_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.unfavorite_post_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.interactions_api.execution_arn}/*/*"
}

##################################################
# LAMBDA: Unfavorite Post Log Group
##################################################
resource "aws_cloudwatch_log_group" "unfavorite_post_log_group" {
  name              = "/aws/lambda/UnfavoritePostFunction"
  retention_in_days = 7
}

##################################################
# LAMBDA: Unfavorite Post Policy
##################################################
resource "aws_iam_policy" "unfavorite_post_lambda_policy" {
  name = "UnfavoritePostPolicy"
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
        aws_cloudwatch_log_group.unfavorite_post_log_group.arn,
        "${aws_cloudwatch_log_group.unfavorite_post_log_group.arn}:*"
      ]
    }]
  })
}

##################################################
# LAMBDA: Unfavorite Post Attach Policy
##################################################
resource "aws_iam_role_policy_attachment" "unfavorite_post_lambda_attach_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.unfavorite_post_lambda_policy.arn
}

##################################################
# LAMBDA: View Post
##################################################
resource "aws_lambda_function" "view_post_lambda" {
  function_name = "ViewPostFunction"
  handler       = "view-post.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_exec.arn

  filename         = "${path.module}/../dist/view-post.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/view-post.zip")

  environment {
    variables = {
      VIEWS_TABLE   = aws_dynamodb_table.post_views.id,
      COUNTER_TABLE = aws_dynamodb_table.post_view_counters.id,
      EVENTS_TABLE  = aws_dynamodb_table.post_events.id,
      ENVIRONMENT   = var.environment
    }
  }
}

##################################################
# LAMBDA: View Post Permission
##################################################
resource "aws_lambda_permission" "api_gateway_view_post_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.view_post_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.interactions_api.execution_arn}/*/*"
}

##################################################
# LAMBDA: View Post Log Group
##################################################
resource "aws_cloudwatch_log_group" "view_post_log_group" {
  name              = "/aws/lambda/ViewPostFunction"
  retention_in_days = 7
}

##################################################
# LAMBDA: View Post Policy
##################################################
resource "aws_iam_policy" "view_post_lambda_policy" {
  name = "ViewPostPolicy"
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
        aws_cloudwatch_log_group.view_post_log_group.arn,
        "${aws_cloudwatch_log_group.view_post_log_group.arn}:*"
      ]
    }]
  })
}

##################################################
# LAMBDA: View Post Attach Policy
##################################################
resource "aws_iam_role_policy_attachment" "view_post_lambda_attach_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.view_post_lambda_policy.arn
}

##################################################
# API Gateway: Posts Resource (`/{post_id}`)
##################################################
resource "aws_api_gateway_resource" "post_resource" {
  rest_api_id = aws_api_gateway_rest_api.interactions_api.id
  parent_id   = aws_api_gateway_rest_api.interactions_api.root_resource_id
  path_part   = "{post_id}"
}

##################################################
# API Gateway: Post Reactions Resource (`/{post_id}/reactions`)
##################################################
resource "aws_api_gateway_resource" "post_reactions_resource" {
  rest_api_id = aws_api_gateway_rest_api.interactions_api.id
  parent_id   = aws_api_gateway_resource.post_resource.id
  path_part   = "reactions"
}

##################################################
# API Gateway: Reaction a Post (POST /{post_id}/reactions)
##################################################
resource "aws_api_gateway_method" "reaction_post_method" {
  rest_api_id   = aws_api_gateway_rest_api.interactions_api.id
  resource_id   = aws_api_gateway_resource.post_reactions_resource.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id

  request_parameters = {
    "method.request.path.post_id" = true
  }
}

resource "aws_api_gateway_integration" "reaction_post_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.interactions_api.id
  resource_id             = aws_api_gateway_resource.post_reactions_resource.id
  http_method             = aws_api_gateway_method.reaction_post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.reaction_post_lambda.invoke_arn

  request_parameters = {
    "integration.request.path.post_id" = "method.request.path.post_id"
  }
}

##################################################
# API Gateway: Remove Reaction from a Post (DELETE /{post_id}/reactions)
##################################################
resource "aws_api_gateway_method" "remove_reaction_post_method" {
  rest_api_id   = aws_api_gateway_rest_api.interactions_api.id
  resource_id   = aws_api_gateway_resource.post_reactions_resource.id
  http_method   = "DELETE"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id

  request_parameters = {
    "method.request.path.post_id" = true
  }
}

resource "aws_api_gateway_integration" "remove_reaction_post_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.interactions_api.id
  resource_id             = aws_api_gateway_resource.post_reactions_resource.id
  http_method             = aws_api_gateway_method.remove_reaction_post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.remove_reaction_post_lambda.invoke_arn

  request_parameters = {
    "integration.request.path.post_id" = "method.request.path.post_id"
  }
}

##################################################
# API Gateway: Post Comments Resource (`/{post_id}/comments`)
##################################################
resource "aws_api_gateway_resource" "post_comments_resource" {
  rest_api_id = aws_api_gateway_rest_api.interactions_api.id
  parent_id   = aws_api_gateway_resource.post_resource.id
  path_part   = "comments"
}

##################################################
# API Gateway: Comment on a Post (POST /{post_id}/comments)
##################################################
resource "aws_api_gateway_method" "comment_post_method" {
  rest_api_id   = aws_api_gateway_rest_api.interactions_api.id
  resource_id   = aws_api_gateway_resource.post_comments_resource.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id

  request_parameters = {
    "method.request.path.post_id" = true
  }
}

resource "aws_api_gateway_integration" "comment_post_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.interactions_api.id
  resource_id             = aws_api_gateway_resource.post_comments_resource.id
  http_method             = aws_api_gateway_method.comment_post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.comment_post_lambda.invoke_arn

  request_parameters = {
    "integration.request.path.post_id" = "method.request.path.post_id"
  }
}

##################################################
# API Gateway: Post Favorites Resource (`/{post_id}/favorites`)
##################################################
resource "aws_api_gateway_resource" "post_favorites_resource" {
  rest_api_id = aws_api_gateway_rest_api.interactions_api.id
  parent_id   = aws_api_gateway_resource.post_resource.id
  path_part   = "favorites"
}

##################################################
# API Gateway: Favorite a Post (POST /{post_id}/favorites)
##################################################
resource "aws_api_gateway_method" "favorite_post_method" {
  rest_api_id   = aws_api_gateway_rest_api.interactions_api.id
  resource_id   = aws_api_gateway_resource.post_favorites_resource.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id

  request_parameters = {
    "method.request.path.post_id" = true
  }
}

resource "aws_api_gateway_integration" "favorite_post_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.interactions_api.id
  resource_id             = aws_api_gateway_resource.post_favorites_resource.id
  http_method             = aws_api_gateway_method.favorite_post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.favorite_post_lambda.invoke_arn

  request_parameters = {
    "integration.request.path.post_id" = "method.request.path.post_id"
  }
}

##################################################
# API Gateway: Unfavorite a Post (DELETE /{post_id}/favorites)
##################################################
resource "aws_api_gateway_method" "unfavorite_post_method" {
  rest_api_id   = aws_api_gateway_rest_api.interactions_api.id
  resource_id   = aws_api_gateway_resource.post_favorites_resource.id
  http_method   = "DELETE"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id

  request_parameters = {
    "method.request.path.post_id" = true
  }
}

resource "aws_api_gateway_integration" "unfavorite_post_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.interactions_api.id
  resource_id             = aws_api_gateway_resource.post_favorites_resource.id
  http_method             = aws_api_gateway_method.unfavorite_post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.unfavorite_post_lambda.invoke_arn

  request_parameters = {
    "integration.request.path.post_id" = "method.request.path.post_id"
  }
}

##################################################
# API Gateway: Post Views Resource (`/{post_id}/views`)
##################################################
resource "aws_api_gateway_resource" "post_views_resource" {
  rest_api_id = aws_api_gateway_rest_api.interactions_api.id
  parent_id   = aws_api_gateway_resource.post_resource.id
  path_part   = "views"
}

##################################################
# API Gateway: View a Post (POST /{post_id}/views)
##################################################
# resource "aws_api_gateway_method" "view_post_method" {
#   rest_api_id   = aws_api_gateway_rest_api


resource "aws_api_gateway_method" "view_post_method" {
  rest_api_id   = aws_api_gateway_rest_api.interactions_api.id
  resource_id   = aws_api_gateway_resource.post_views_resource.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.custom_authorizer.id

  request_parameters = {
    "method.request.path.post_id" = true
  }
}

resource "aws_api_gateway_integration" "view_post_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.interactions_api.id
  resource_id             = aws_api_gateway_resource.post_views_resource.id
  http_method             = aws_api_gateway_method.view_post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.view_post_lambda.invoke_arn

  request_parameters = {
    "integration.request.path.post_id" = "method.request.path.post_id"
  }
}

##################################################
# LAMBDA: View Post
##################################################
resource "aws_lambda_function" "flush_view_counts" {
  function_name = "FlushViewCounts"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "flush-view-counts.handler"
  runtime       = "nodejs20.x"

  filename         = "${path.module}/../dist/flush-view-counts.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/flush-view-counts.zip")

  environment {
    variables = {
      VIEWS_TABLE         = aws_dynamodb_table.post_views.name
      VIEW_COUNTERS_TABLE = aws_dynamodb_table.post_view_counters.name
      ENVIRONMENT         = var.environment
    }
  }
}

resource "aws_cloudwatch_event_rule" "flush_view_counts_schedule" {
  name                = "FlushViewCountsSchedule"
  schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "flush_view_counts_target" {
  rule      = aws_cloudwatch_event_rule.flush_view_counts_schedule.name
  target_id = "FlushViewCountsLambda"
  arn       = aws_lambda_function.flush_view_counts.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_flush_view_counts" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.flush_view_counts.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.flush_view_counts_schedule.arn
}
