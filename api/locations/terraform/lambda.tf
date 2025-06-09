####################################################################################################
# Lambda Execution Role
####################################################################################################

##################################################
# LAMBDA: Locations API Lambda Exec Role
##################################################
resource "aws_iam_role" "lambda_exec" {
  name = "locations_api_lambda_exec_role"

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
# LAMBDA: Attach Lambda Policy to Lambda Exec Role
##################################################
resource "aws_iam_role_policy_attachment" "locations_lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

####################################################################################################
# Get Districts Lambda
####################################################################################################

##################################################
# LAMBDA: Locations Get Districts Lambda
##################################################
resource "aws_lambda_function" "locations_get_districts_lambda" {
  function_name = "LocationsGetDistrictsFunction"
  handler       = "locations-get-districts.handler"
  runtime       = var.lambda_runtime
  role          = aws_iam_role.lambda_exec.arn

  filename         = "${path.module}/../dist/locations-get-districts.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/locations-get-districts.zip")

  environment {
    variables = {
      LOG_LEVEL         = "INFO"
      OPENSEARCH_DOMAIN = "https://${aws_opensearch_domain.location.endpoint}"
      DISTRICTS_INDEX   = "districts-geo-index"
      REQUIRED_SCOPE    = ""
    }
  }

  timeout = 10
}

##################################################
# LAMBDA: Locations Get Districts Permission
##################################################
resource "aws_lambda_permission" "api_gateway_locations_get_districts_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.locations_get_districts_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.locations_api.execution_arn}/*/*"
}

##################################################
# LAMBDA: Locations Get Districts Log Group
##################################################
resource "aws_cloudwatch_log_group" "locations_get_districts_log_group" {
  name              = "/aws/lambda/LocationsGetDistrictsFunction"
  retention_in_days = 7
}

##################################################
# LAMBDA: Locations Get Districts Policy
##################################################
resource "aws_iam_policy" "locations_get_districts_lambda_policy" {
  name = "LocationsGetDistrictsPolicy"
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
        aws_cloudwatch_log_group.locations_get_districts_log_group.arn,
        "${aws_cloudwatch_log_group.locations_get_districts_log_group.arn}:*"
      ]
    }]
  })
}

##################################################
# LAMBDA: Locations Get Districts Attach Policy
##################################################
resource "aws_iam_role_policy_attachment" "locations_get_districts_lambda_attach_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.locations_get_districts_lambda_policy.arn
}

####################################################################################################
# Get Schools Lambda
####################################################################################################

##################################################
# LAMBDA: Locations Get Schools Lambda
##################################################
resource "aws_lambda_function" "locations_get_schools_lambda" {
  function_name = "LocationsGetSchoolsFunction"
  handler       = "locations-get-schools.handler"
  runtime       = var.lambda_runtime
  role          = aws_iam_role.lambda_exec.arn

  filename         = "${path.module}/../dist/locations-get-schools.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/locations-get-schools.zip")

  environment {
    variables = {
      LOG_LEVEL         = "INFO"
      OPENSEARCH_DOMAIN = "https://${aws_opensearch_domain.location.endpoint}"
      SCHOOLS_INDEX     = "schools-geo-index"
      REQUIRED_SCOPE    = ""
    }
  }

  timeout = 10
}

##################################################
# LAMBDA: Locations Get Schools Permission
##################################################
resource "aws_lambda_permission" "api_gateway_locations_get_schools_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.locations_get_schools_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.locations_api.execution_arn}/*/*"
}

##################################################
# LAMBDA: Locations Get Schools Log Group
##################################################
resource "aws_cloudwatch_log_group" "locations_get_schools_log_group" {
  name              = "/aws/lambda/LocationsGetSchoolsFunction"
  retention_in_days = 7
}

##################################################
# LAMBDA: Locations Get Schools Policy
##################################################
resource "aws_iam_policy" "locations_get_schools_lambda_policy" {
  name = "LocationsGetSchoolsPolicy"
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
        aws_cloudwatch_log_group.locations_get_schools_log_group.arn,
        "${aws_cloudwatch_log_group.locations_get_schools_log_group.arn}:*"
      ]
    }]
  })
}

##################################################
# LAMBDA: Locations Get Schools Attach Policy
##################################################
resource "aws_iam_role_policy_attachment" "locations_get_schools_lambda_attach_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.locations_get_schools_lambda_policy.arn
}

####################################################################################################
# Get GeoCodes Lambda
####################################################################################################

##################################################
# LAMBDA: Locations Get GeoCodes Lambda
##################################################
resource "aws_lambda_function" "locations_get_geocode_lambda" {
  function_name = "LocationsGetGeocodeFunction"
  handler       = "locations-get-geocode.handler"
  runtime       = var.lambda_runtime
  role          = aws_iam_role.lambda_exec.arn

  filename         = "${path.module}/../dist/locations-get-geocode.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/locations-get-geocode.zip")

  environment {
    variables = {
      LOG_LEVEL        = "INFO"
      PLACE_INDEX_NAME = aws_location_place_index.esri_place_index.index_name
      REQUIRED_SCOPE   = ""
    }
  }

  timeout = 10
}

##################################################
# LAMBDA: Locations Get GeoCodes Permission
##################################################
resource "aws_lambda_permission" "api_gateway_locations_get_geocode_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.locations_get_geocode_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.locations_api.execution_arn}/*/*"
}

##################################################
# LAMBDA: Locations Get GeoCodes Log Group
##################################################
resource "aws_cloudwatch_log_group" "locations_get_geocode_log_group" {
  name              = "/aws/lambda/LocationsGetGeocodeFunction"
  retention_in_days = 7
}

##################################################
# LAMBDA: Locations Get GeoCodes Policy
##################################################
resource "aws_iam_policy" "locations_get_geocode_lambda_policy" {
  name = "LocationsGetGeoCodePolicy"
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
        aws_cloudwatch_log_group.locations_get_geocode_log_group.arn,
        "${aws_cloudwatch_log_group.locations_get_geocode_log_group.arn}:*"
      ]
    }]
  })
}

##################################################
# LAMBDA: Locations Get GeoCodes Attach Policy
##################################################
resource "aws_iam_role_policy_attachment" "locations_get_geocode_lambda_attach_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.locations_get_geocode_lambda_policy.arn
}

####################################################################################################
# Get Suggestions Lambda
####################################################################################################

##################################################
# LAMBDA: Locations Get Suggestions Lambda
##################################################
resource "aws_lambda_function" "locations_get_suggestions_lambda" {
  function_name = "LocationsGetSuggestionsFunction"
  handler       = "locations-get-suggestions.handler"
  runtime       = var.lambda_runtime
  role          = aws_iam_role.lambda_exec.arn

  filename         = "${path.module}/../dist/locations-get-suggestions.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/locations-get-suggestions.zip")

  environment {
    variables = {
      LOG_LEVEL        = "INFO"
      PLACE_INDEX_NAME = aws_location_place_index.esri_place_index.index_name
      REQUIRED_SCOPE   = ""
    }
  }

  timeout = 10
}

##################################################
# LAMBDA: Locations Get Suggestions Permission
##################################################
resource "aws_lambda_permission" "api_gateway_locations_get_suggestions_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.locations_get_suggestions_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.locations_api.execution_arn}/*/*"
}

##################################################
# LAMBDA: Locations Get Suggestions Log Group
##################################################
resource "aws_cloudwatch_log_group" "locations_get_suggestions_log_group" {
  name              = "/aws/lambda/LocationsGetSuggestionsFunction"
  retention_in_days = 7
}

##################################################
# LAMBDA: Locations Get Suggestions Policy
##################################################
resource "aws_iam_policy" "locations_get_suggestions_lambda_policy" {
  name = "LocationsGetSuggestionsPolicy"
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
        aws_cloudwatch_log_group.locations_get_suggestions_log_group.arn,
        "${aws_cloudwatch_log_group.locations_get_suggestions_log_group.arn}:*"
      ]
      },
      {
        Effect = "Allow",
        Action = [
          "geo:SearchPlaceIndexForText"
        ],
        Resource = "${aws_location_place_index.esri_place_index.index_arn}"
    }]
  })
}

##################################################
# LAMBDA: Locations Get Suggestions Attach Policy
##################################################
resource "aws_iam_role_policy_attachment" "locations_get_suggestions_lambda_attach_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.locations_get_suggestions_lambda_policy.arn
}

####################################################################################################
# Get Item Lambda
####################################################################################################

##################################################
# LAMBDA: Locations Get Item Lambda
##################################################
resource "aws_lambda_function" "locations_get_item_lambda" {
  function_name = "LocationsGetItemFunction"
  handler       = "locations-get-item.handler"
  runtime       = var.lambda_runtime
  role          = aws_iam_role.lambda_exec.arn

  filename         = "${path.module}/../dist/locations-get-item.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/locations-get-item.zip")

  environment {
    variables = {
      LOG_LEVEL        = "INFO"
      PLACE_INDEX_NAME = aws_location_place_index.esri_place_index.index_name
      REQUIRED_SCOPE   = ""
    }
  }

  timeout = 10
}

##################################################
# LAMBDA: Locations Get Item Permission
##################################################
resource "aws_lambda_permission" "api_gateway_locations_get_item_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.locations_get_item_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.locations_api.execution_arn}/*/*"
}

##################################################
# LAMBDA: Locations Get Item Log Group
##################################################
resource "aws_cloudwatch_log_group" "locations_get_item_log_group" {
  name              = "/aws/lambda/LocationsGetItemFunction"
  retention_in_days = 7
}

##################################################
# LAMBDA: Locations Get Item Policy
##################################################
resource "aws_iam_policy" "locations_get_item_lambda_policy" {
  name = "LocationsGetItemPolicy"
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
        aws_cloudwatch_log_group.locations_get_item_log_group.arn,
        "${aws_cloudwatch_log_group.locations_get_item_log_group.arn}:*"
      ]
    }]
  })
}

##################################################
# LAMBDA: Locations Get Item Attach Policy
##################################################
resource "aws_iam_role_policy_attachment" "locations_get_item_lambda_attach_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.locations_get_item_lambda_policy.arn
}
