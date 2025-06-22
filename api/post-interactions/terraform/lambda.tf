# Use the current AWS region and account

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
        aws_dynamodb_table.post_comments.arn,
        aws_dynamodb_table.comment_reactions.arn,
        aws_dynamodb_table.post_user_favorites.arn,
        aws_dynamodb_table.post_view_counters.arn,
        aws_dynamodb_table.post_views.arn,
        "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/posts",
        "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/user_profile"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "dynamodb_access_attachment" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.dynamodb_access_policy.arn
}

##################################################
# Consolidated Lambda Logging Policy
##################################################
resource "aws_iam_policy" "lambda_logging_policy" {
  name = "LambdaLoggingPolicy"
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
        aws_cloudwatch_log_group.post_interactions_remove_reaction_log_group.arn,
        "${aws_cloudwatch_log_group.post_interactions_remove_reaction_log_group.arn}:*",
        aws_cloudwatch_log_group.post_interactions_comment_log_group.arn,
        "${aws_cloudwatch_log_group.post_interactions_comment_log_group.arn}:*",
        aws_cloudwatch_log_group.post_interactions_favorite_log_group.arn,
        "${aws_cloudwatch_log_group.post_interactions_favorite_log_group.arn}:*",
        aws_cloudwatch_log_group.post_interactions_unfavorite_log_group.arn,
        "${aws_cloudwatch_log_group.post_interactions_unfavorite_log_group.arn}:*",
        aws_cloudwatch_log_group.post_interactions_view_log_group.arn,
        "${aws_cloudwatch_log_group.post_interactions_view_log_group.arn}:*",
        aws_cloudwatch_log_group.post_interactions_add_reaction_log_group.arn,
        "${aws_cloudwatch_log_group.post_interactions_add_reaction_log_group.arn}:*",
        aws_cloudwatch_log_group.post_interactions_update_reaction_log_group.arn,
        "${aws_cloudwatch_log_group.post_interactions_update_reaction_log_group.arn}:*",
        aws_cloudwatch_log_group.post_interactions_delete_reaction_log_group.arn,
        "${aws_cloudwatch_log_group.post_interactions_delete_reaction_log_group.arn}:*",
        aws_cloudwatch_log_group.post_interactions_get_reaction_log_group.arn,
        "${aws_cloudwatch_log_group.post_interactions_get_reaction_log_group.arn}:*",
        aws_cloudwatch_log_group.post_interactions_get_comments_log_group.arn,
        "${aws_cloudwatch_log_group.post_interactions_get_comments_log_group.arn}:*",
        aws_cloudwatch_log_group.post_interactions_reply_comment_log_group.arn,
        "${aws_cloudwatch_log_group.post_interactions_reply_comment_log_group.arn}:*",
        aws_cloudwatch_log_group.post_interactions_add_comment_reaction_log_group.arn,
        "${aws_cloudwatch_log_group.post_interactions_add_comment_reaction_log_group.arn}:*",
        aws_cloudwatch_log_group.post_interactions_update_comment_reaction_log_group.arn,
        "${aws_cloudwatch_log_group.post_interactions_update_comment_reaction_log_group.arn}:*",
        aws_cloudwatch_log_group.post_interactions_delete_comment_reaction_log_group.arn,
        "${aws_cloudwatch_log_group.post_interactions_delete_comment_reaction_log_group.arn}:*",
        aws_cloudwatch_log_group.post_interactions_get_comment_reaction_log_group.arn,
        "${aws_cloudwatch_log_group.post_interactions_get_comment_reaction_log_group.arn}:*"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logging_policy_attachment" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_logging_policy.arn
}

##################################################
# LAMBDA: Remove Reaction Post
##################################################
resource "aws_lambda_function" "post_interactions_remove_reaction_lambda" {
  function_name = "PostInteractionsRemoveReactionFunction"
  handler       = "remove-reaction-from-post.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_exec.arn

  filename         = "${path.module}/../dist/remove-reaction-from-post.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/remove-reaction-from-post.zip")

  environment {
    variables = {
      REACTIONS_TABLE = aws_dynamodb_table.post_reactions.id,
      EVENTS_TABLE    = aws_dynamodb_table.post_events.id,
      POSTS_TABLE     = "posts",
      ENVIRONMENT     = var.environment
    }
  }
}

##################################################
# LAMBDA: Remove Reaction Post Permission
##################################################
resource "aws_lambda_permission" "api_gateway_post_interactions_remove_reaction_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_interactions_remove_reaction_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.interactions_api.execution_arn}/*/*"
}

##################################################
# LAMBDA: Remove Reaction Post Log Group
##################################################
resource "aws_cloudwatch_log_group" "post_interactions_remove_reaction_log_group" {
  name              = "/aws/lambda/PostInteractionsRemoveReactionFunction"
  retention_in_days = 7
}

##################################################
# LAMBDA: Remove Reaction Post Policy
##################################################
resource "aws_iam_policy" "post_interactions_remove_reaction_lambda_policy" {
  name = "PostInteractionsRemoveReactionPolicy"
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
        aws_cloudwatch_log_group.post_interactions_remove_reaction_log_group.arn,
        "${aws_cloudwatch_log_group.post_interactions_remove_reaction_log_group.arn}:*"
      ]
    }]
  })
}

##################################################
# LAMBDA: Remove Reaction Post Attach Policy
##################################################
resource "aws_iam_role_policy_attachment" "post_interactions_remove_reaction_lambda_attach_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.post_interactions_remove_reaction_lambda_policy.arn
}

##################################################
# LAMBDA: Comment Post
##################################################
resource "aws_lambda_function" "post_interactions_comment_lambda" {
  function_name = "PostInteractionsCommentFunction"
  handler       = "comment-on-post.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_exec.arn

  filename         = "${path.module}/../dist/comment-on-post.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/comment-on-post.zip")

  environment {
    variables = {
      COMMENTS_TABLE     = aws_dynamodb_table.post_comments.id,
      EVENTS_TABLE       = aws_dynamodb_table.post_events.id,
      POSTS_TABLE        = "posts",
      USER_PROFILE_TABLE = "user_profile",
      ENVIRONMENT        = var.environment
    }
  }
}

##################################################
# LAMBDA: Comment Post Permission
##################################################
resource "aws_lambda_permission" "api_gateway_post_interactions_comment_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_interactions_comment_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.interactions_api.execution_arn}/*/*"
}

##################################################
# LAMBDA: Comment Post Log Group
##################################################
resource "aws_cloudwatch_log_group" "post_interactions_comment_log_group" {
  name              = "/aws/lambda/PostInteractionsCommentFunction"
  retention_in_days = 7
}

##################################################
# LAMBDA: Comment Post Policy
##################################################
resource "aws_iam_policy" "post_interactions_comment_lambda_policy" {
  name = "PostInteractionsCommentPolicy"
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
        aws_cloudwatch_log_group.post_interactions_comment_log_group.arn,
        "${aws_cloudwatch_log_group.post_interactions_comment_log_group.arn}:*"
      ]
    }]
  })
}

##################################################
# LAMBDA: Comment Post Attach Policy
##################################################
resource "aws_iam_role_policy_attachment" "post_interactions_comment_lambda_attach_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.post_interactions_comment_lambda_policy.arn
}

##################################################
# LAMBDA: Favorite Post
##################################################
resource "aws_lambda_function" "post_interactions_favorite_lambda" {
  function_name = "PostInteractionsFavoriteFunction"
  handler       = "favorite-post.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_exec.arn

  filename         = "${path.module}/../dist/favorite-post.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/favorite-post.zip")

  environment {
    variables = {
      FAVORITES_TABLE = aws_dynamodb_table.post_user_favorites.id,
      EVENTS_TABLE    = aws_dynamodb_table.post_events.id,
      POSTS_TABLE     = "posts",
      ENVIRONMENT     = var.environment
    }
  }
}

##################################################
# LAMBDA: Favorite Post Permission
##################################################
resource "aws_lambda_permission" "api_gateway_post_interactions_favorite_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_interactions_favorite_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.interactions_api.execution_arn}/*/*"
}

##################################################
# LAMBDA: Favorite Post Log Group
##################################################
resource "aws_cloudwatch_log_group" "post_interactions_favorite_log_group" {
  name              = "/aws/lambda/PostInteractionsFavoriteFunction"
  retention_in_days = 7
}

##################################################
# LAMBDA: Favorite Post Policy
##################################################
resource "aws_iam_policy" "post_interactions_favorite_lambda_policy" {
  name = "PostInteractionsFavoritePolicy"
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
        aws_cloudwatch_log_group.post_interactions_favorite_log_group.arn,
        "${aws_cloudwatch_log_group.post_interactions_favorite_log_group.arn}:*"
      ]
    }]
  })
}

##################################################
# LAMBDA: Favorite Post Attach Policy
##################################################
resource "aws_iam_role_policy_attachment" "post_interactions_favorite_lambda_attach_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.post_interactions_favorite_lambda_policy.arn
}

##################################################
# LAMBDA: Unfavorite Post
##################################################
resource "aws_lambda_function" "post_interactions_unfavorite_lambda" {
  function_name = "PostInteractionsUnfavoriteFunction"
  handler       = "unfavorite-post.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_exec.arn

  filename         = "${path.module}/../dist/unfavorite-post.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/unfavorite-post.zip")

  environment {
    variables = {
      FAVORITES_TABLE = aws_dynamodb_table.post_user_favorites.id,
      EVENTS_TABLE    = aws_dynamodb_table.post_events.id,
      POSTS_TABLE     = "posts",
      ENVIRONMENT     = var.environment
    }
  }
}

##################################################
# LAMBDA: Unfavorite Post Permission
##################################################
resource "aws_lambda_permission" "api_gateway_post_interactions_unfavorite_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_interactions_unfavorite_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.interactions_api.execution_arn}/*/*"
}

##################################################
# LAMBDA: Unfavorite Post Log Group
##################################################
resource "aws_cloudwatch_log_group" "post_interactions_unfavorite_log_group" {
  name              = "/aws/lambda/PostInteractionsUnfavoriteFunction"
  retention_in_days = 7
}

##################################################
# LAMBDA: Unfavorite Post Policy
##################################################
resource "aws_iam_policy" "post_interactions_unfavorite_lambda_policy" {
  name = "PostInteractionsUnfavoritePolicy"
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
        aws_cloudwatch_log_group.post_interactions_unfavorite_log_group.arn,
        "${aws_cloudwatch_log_group.post_interactions_unfavorite_log_group.arn}:*"
      ]
    }]
  })
}

##################################################
# LAMBDA: Unfavorite Post Attach Policy
##################################################
resource "aws_iam_role_policy_attachment" "post_interactions_unfavorite_lambda_attach_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.post_interactions_unfavorite_lambda_policy.arn
}

##################################################
# LAMBDA: View Post
##################################################
resource "aws_lambda_function" "post_interactions_view_lambda" {
  function_name = "PostInteractionsViewFunction"
  handler       = "view-post.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_exec.arn

  filename         = "${path.module}/../dist/view-post.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/view-post.zip")

  environment {
    variables = {
      VIEWS_TABLE  = aws_dynamodb_table.post_views.id,
      EVENTS_TABLE = aws_dynamodb_table.post_events.id,
      POSTS_TABLE  = "posts",
      ENVIRONMENT  = var.environment
    }
  }
}

##################################################
# LAMBDA: View Post Permission
##################################################
resource "aws_lambda_permission" "api_gateway_post_interactions_view_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_interactions_view_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.interactions_api.execution_arn}/*/*"
}

##################################################
# LAMBDA: View Post Log Group
##################################################
resource "aws_cloudwatch_log_group" "post_interactions_view_log_group" {
  name              = "/aws/lambda/PostInteractionsViewFunction"
  retention_in_days = 7
}

##################################################
# LAMBDA: View Post Policy
##################################################
resource "aws_iam_policy" "post_interactions_view_lambda_policy" {
  name = "PostInteractionsViewPolicy"
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
        aws_cloudwatch_log_group.post_interactions_view_log_group.arn,
        "${aws_cloudwatch_log_group.post_interactions_view_log_group.arn}:*"
      ]
    }]
  })
}

##################################################
# LAMBDA: View Post Attach Policy
##################################################
resource "aws_iam_role_policy_attachment" "post_interactions_view_lambda_attach_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.post_interactions_view_lambda_policy.arn
}

##################################################
# LAMBDA: Flush View Counts (Scheduled)
##################################################
resource "aws_lambda_function" "flush_view_counts" {
  function_name = "PostInteractionsFlushViewCountsFunction"
  handler       = "flush-view-counts.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_exec.arn

  filename         = "${path.module}/../dist/flush-view-counts.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/flush-view-counts.zip")

  environment {
    variables = {
      VIEWS_TABLE = aws_dynamodb_table.post_views.id,
      POSTS_TABLE = "posts",
      ENVIRONMENT = var.environment
    }
  }
}

##################################################
# LAMBDA: Flush View Counts Schedule
##################################################
resource "aws_cloudwatch_event_rule" "flush_view_counts_schedule" {
  name                = "flush-view-counts-schedule"
  description         = "Schedule for flushing view counts to posts table"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "flush_view_counts_target" {
  rule      = aws_cloudwatch_event_rule.flush_view_counts_schedule.name
  target_id = "FlushViewCountsTarget"
  arn       = aws_lambda_function.flush_view_counts.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_flush_view_counts" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.flush_view_counts.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.flush_view_counts_schedule.arn
}

##################################################
# LAMBDA: Post Interactions Authorizer
##################################################
resource "aws_iam_role" "post_interactions_authorizer_lambda_exec" {
  name = "post_interactions_authorizer_lambda_exec_role"

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

resource "aws_iam_role_policy_attachment" "post_interactions_authorizer_lambda_logs" {
  role       = aws_iam_role.post_interactions_authorizer_lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "post_interactions_authorizer_lambda" {
  function_name = "PostInteractionsAuthorizerFunction"
  handler       = "post-interactions-authorizer.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.post_interactions_authorizer_lambda_exec.arn

  filename         = "${path.module}/../dist/post-interactions-authorizer.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/post-interactions-authorizer.zip")

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }
}

##################################################
# LAMBDA: Post Interactions Authorizer Log Group
##################################################
resource "aws_cloudwatch_log_group" "post_interactions_authorizer_lambda_log_group" {
  name              = "/aws/lambda/PostInteractionsAuthorizerFunction"
  retention_in_days = 7
}

##################################################
# LAMBDA: Post Interactions Authorizer Policy
##################################################
resource "aws_iam_policy" "post_interactions_authorizer_lambda_policy" {
  name = "PostInteractionsAuthorizerPolicy"
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
        aws_cloudwatch_log_group.post_interactions_authorizer_lambda_log_group.arn,
        "${aws_cloudwatch_log_group.post_interactions_authorizer_lambda_log_group.arn}:*"
      ]
    }]
  })
}

resource "aws_iam_policy" "post_interactions_authorizer_firebase_secrets_policy" {
  name = "PostInteractionsAuthorizerFirebaseSecretsPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "secretsmanager:GetSecretValue"
      ]
      Effect = "Allow"
      Resource = [
        "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:firebase/service-account-key*"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "post_interactions_authorizer_lambda_attach_policy" {
  role       = aws_iam_role.post_interactions_authorizer_lambda_exec.name
  policy_arn = aws_iam_policy.post_interactions_authorizer_lambda_policy.arn
}

resource "aws_iam_role_policy_attachment" "post_interactions_authorizer_firebase_secrets_attachment" {
  role       = aws_iam_role.post_interactions_authorizer_lambda_exec.name
  policy_arn = aws_iam_policy.post_interactions_authorizer_firebase_secrets_policy.arn
}

resource "aws_lambda_permission" "api_gateway_post_interactions_authorizer_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_interactions_authorizer_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.interactions_api.execution_arn}/*/*"
}

##################################################
# LAMBDA: Add Post Reaction
##################################################
resource "aws_lambda_function" "post_interactions_add_reaction_lambda" {
  function_name = "PostInteractionsAddReactionFunction"
  handler       = "post-reactions.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_exec.arn

  filename         = "${path.module}/../dist/post-reactions.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/post-reactions.zip")

  environment {
    variables = {
      REACTIONS_TABLE = aws_dynamodb_table.post_reactions.id,
      EVENTS_TABLE    = aws_dynamodb_table.post_events.id,
      POSTS_TABLE     = "posts",
      ENVIRONMENT     = var.environment
    }
  }
}

##################################################
# LAMBDA: Add Post Reaction Permission
##################################################
resource "aws_lambda_permission" "api_gateway_post_interactions_add_reaction_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_interactions_add_reaction_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.interactions_api.execution_arn}/*/*"
}

##################################################
# LAMBDA: Add Post Reaction Log Group
##################################################
resource "aws_cloudwatch_log_group" "post_interactions_add_reaction_log_group" {
  name              = "/aws/lambda/PostInteractionsAddReactionFunction"
  retention_in_days = 7
}

##################################################
# LAMBDA: Update Post Reaction
##################################################
resource "aws_lambda_function" "post_interactions_update_reaction_lambda" {
  function_name = "PostInteractionsUpdateReactionFunction"
  handler       = "put-reactions.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_exec.arn

  filename         = "${path.module}/../dist/put-reactions.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/put-reactions.zip")

  environment {
    variables = {
      REACTIONS_TABLE = aws_dynamodb_table.post_reactions.id,
      EVENTS_TABLE    = aws_dynamodb_table.post_events.id,
      POSTS_TABLE     = "posts",
      ENVIRONMENT     = var.environment
    }
  }
}

##################################################
# LAMBDA: Update Post Reaction Permission
##################################################
resource "aws_lambda_permission" "api_gateway_post_interactions_update_reaction_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_interactions_update_reaction_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.interactions_api.execution_arn}/*/*"
}

##################################################
# LAMBDA: Update Post Reaction Log Group
##################################################
resource "aws_cloudwatch_log_group" "post_interactions_update_reaction_log_group" {
  name              = "/aws/lambda/PostInteractionsUpdateReactionFunction"
  retention_in_days = 7
}

##################################################
# LAMBDA: Delete Post Reaction
##################################################
resource "aws_lambda_function" "post_interactions_delete_reaction_lambda" {
  function_name = "PostInteractionsDeleteReactionFunction"
  handler       = "delete-reactions.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_exec.arn

  filename         = "${path.module}/../dist/delete-reactions.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/delete-reactions.zip")

  environment {
    variables = {
      REACTIONS_TABLE = aws_dynamodb_table.post_reactions.id,
      EVENTS_TABLE    = aws_dynamodb_table.post_events.id,
      POSTS_TABLE     = "posts",
      ENVIRONMENT     = var.environment
    }
  }
}

##################################################
# LAMBDA: Delete Post Reaction Permission
##################################################
resource "aws_lambda_permission" "api_gateway_post_interactions_delete_reaction_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_interactions_delete_reaction_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.interactions_api.execution_arn}/*/*"
}

##################################################
# LAMBDA: Delete Post Reaction Log Group
##################################################
resource "aws_cloudwatch_log_group" "post_interactions_delete_reaction_log_group" {
  name              = "/aws/lambda/PostInteractionsDeleteReactionFunction"
  retention_in_days = 7
}

##################################################
# LAMBDA: Get Post Reaction
##################################################
resource "aws_lambda_function" "post_interactions_get_reaction_lambda" {
  function_name = "PostInteractionsGetReactionFunction"
  handler       = "get-reactions.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_exec.arn

  filename         = "${path.module}/../dist/get-reactions.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/get-reactions.zip")

  environment {
    variables = {
      REACTIONS_TABLE = aws_dynamodb_table.post_reactions.id,
      POSTS_TABLE     = "posts",
      ENVIRONMENT     = var.environment
    }
  }
}

##################################################
# LAMBDA: Get Post Reaction Permission
##################################################
resource "aws_lambda_permission" "api_gateway_post_interactions_get_reaction_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_interactions_get_reaction_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.interactions_api.execution_arn}/*/*"
}

##################################################
# LAMBDA: Get Post Reaction Log Group
##################################################
resource "aws_cloudwatch_log_group" "post_interactions_get_reaction_log_group" {
  name              = "/aws/lambda/PostInteractionsGetReactionFunction"
  retention_in_days = 7
}

##################################################
# LAMBDA: Get Comments
##################################################
resource "aws_lambda_function" "post_interactions_get_comments_lambda" {
  function_name = "PostInteractionsGetCommentsFunction"
  handler       = "get-comments.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_exec.arn

  filename         = "${path.module}/../dist/get-comments.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/get-comments.zip")

  environment {
    variables = {
      COMMENTS_TABLE     = aws_dynamodb_table.post_comments.id,
      USER_PROFILE_TABLE = "user_profile",
      ENVIRONMENT        = var.environment
    }
  }
}

##################################################
# LAMBDA: Get Comments Permission
##################################################
resource "aws_lambda_permission" "api_gateway_post_interactions_get_comments_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_interactions_get_comments_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.interactions_api.execution_arn}/*/*"
}

##################################################
# LAMBDA: Get Comments Log Group
##################################################
resource "aws_cloudwatch_log_group" "post_interactions_get_comments_log_group" {
  name              = "/aws/lambda/PostInteractionsGetCommentsFunction"
  retention_in_days = 7
}

##################################################
# LAMBDA: Reply to Comment
##################################################
resource "aws_lambda_function" "post_interactions_reply_comment_lambda" {
  function_name = "PostInteractionsReplyCommentFunction"
  handler       = "reply-to-comment.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_exec.arn

  filename         = "${path.module}/../dist/reply-to-comment.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/reply-to-comment.zip")

  environment {
    variables = {
      COMMENTS_TABLE     = aws_dynamodb_table.post_comments.id,
      EVENTS_TABLE       = aws_dynamodb_table.post_events.id,
      POSTS_TABLE        = "posts",
      USER_PROFILE_TABLE = "user_profile",
      ENVIRONMENT        = var.environment
    }
  }
}

##################################################
# LAMBDA: Reply to Comment Permission
##################################################
resource "aws_lambda_permission" "api_gateway_post_interactions_reply_comment_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_interactions_reply_comment_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.interactions_api.execution_arn}/*/*"
}

##################################################
# LAMBDA: Reply to Comment Log Group
##################################################
resource "aws_cloudwatch_log_group" "post_interactions_reply_comment_log_group" {
  name              = "/aws/lambda/PostInteractionsReplyCommentFunction"
  retention_in_days = 7
}

##################################################
# LAMBDA: Add Comment Reaction
##################################################
resource "aws_lambda_function" "post_interactions_add_comment_reaction_lambda" {
  function_name = "PostInteractionsAddCommentReactionFunction"
  handler       = "comment-reactions.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_exec.arn

  filename         = "${path.module}/../dist/comment-reactions.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/comment-reactions.zip")

  environment {
    variables = {
      COMMENT_REACTIONS_TABLE = aws_dynamodb_table.comment_reactions.id,
      EVENTS_TABLE            = aws_dynamodb_table.post_events.id,
      POSTS_TABLE             = "posts",
      ENVIRONMENT             = var.environment
    }
  }
}

##################################################
# LAMBDA: Add Comment Reaction Permission
##################################################
resource "aws_lambda_permission" "api_gateway_post_interactions_add_comment_reaction_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_interactions_add_comment_reaction_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.interactions_api.execution_arn}/*/*"
}

##################################################
# LAMBDA: Add Comment Reaction Log Group
##################################################
resource "aws_cloudwatch_log_group" "post_interactions_add_comment_reaction_log_group" {
  name              = "/aws/lambda/PostInteractionsAddCommentReactionFunction"
  retention_in_days = 7
}

##################################################
# LAMBDA: Update Comment Reaction
##################################################
resource "aws_lambda_function" "post_interactions_update_comment_reaction_lambda" {
  function_name = "PostInteractionsUpdateCommentReactionFunction"
  handler       = "update-comment-reaction.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_exec.arn

  filename         = "${path.module}/../dist/update-comment-reaction.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/update-comment-reaction.zip")

  environment {
    variables = {
      COMMENT_REACTIONS_TABLE = aws_dynamodb_table.comment_reactions.id,
      EVENTS_TABLE            = aws_dynamodb_table.post_events.id,
      POSTS_TABLE             = "posts",
      ENVIRONMENT             = var.environment
    }
  }
}

##################################################
# LAMBDA: Update Comment Reaction Permission
##################################################
resource "aws_lambda_permission" "api_gateway_post_interactions_update_comment_reaction_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_interactions_update_comment_reaction_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.interactions_api.execution_arn}/*/*"
}

##################################################
# LAMBDA: Update Comment Reaction Log Group
##################################################
resource "aws_cloudwatch_log_group" "post_interactions_update_comment_reaction_log_group" {
  name              = "/aws/lambda/PostInteractionsUpdateCommentReactionFunction"
  retention_in_days = 7
}

##################################################
# LAMBDA: Delete Comment Reaction
##################################################
resource "aws_lambda_function" "post_interactions_delete_comment_reaction_lambda" {
  function_name = "PostInteractionsDeleteCommentReactionFunction"
  handler       = "delete-comment-reaction.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_exec.arn

  filename         = "${path.module}/../dist/delete-comment-reaction.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/delete-comment-reaction.zip")

  environment {
    variables = {
      COMMENT_REACTIONS_TABLE = aws_dynamodb_table.comment_reactions.id,
      EVENTS_TABLE            = aws_dynamodb_table.post_events.id,
      POSTS_TABLE             = "posts",
      ENVIRONMENT             = var.environment
    }
  }
}

##################################################
# LAMBDA: Delete Comment Reaction Permission
##################################################
resource "aws_lambda_permission" "api_gateway_post_interactions_delete_comment_reaction_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_interactions_delete_comment_reaction_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.interactions_api.execution_arn}/*/*"
}

##################################################
# LAMBDA: Delete Comment Reaction Log Group
##################################################
resource "aws_cloudwatch_log_group" "post_interactions_delete_comment_reaction_log_group" {
  name              = "/aws/lambda/PostInteractionsDeleteCommentReactionFunction"
  retention_in_days = 7
}

##################################################
# LAMBDA: Get Comment Reaction
##################################################
resource "aws_lambda_function" "post_interactions_get_comment_reaction_lambda" {
  function_name = "PostInteractionsGetCommentReactionFunction"
  handler       = "get-comment-reactions.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_exec.arn

  filename         = "${path.module}/../dist/get-comment-reactions.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/get-comment-reactions.zip")

  environment {
    variables = {
      COMMENT_REACTIONS_TABLE = aws_dynamodb_table.comment_reactions.id,
      POSTS_TABLE             = "posts",
      ENVIRONMENT             = var.environment
    }
  }
}

##################################################
# LAMBDA: Get Comment Reaction Permission
##################################################
resource "aws_lambda_permission" "api_gateway_post_interactions_get_comment_reaction_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_interactions_get_comment_reaction_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.interactions_api.execution_arn}/*/*"
}

##################################################
# LAMBDA: Get Comment Reaction Log Group
##################################################
resource "aws_cloudwatch_log_group" "post_interactions_get_comment_reaction_log_group" {
  name              = "/aws/lambda/PostInteractionsGetCommentReactionFunction"
  retention_in_days = 7
}
