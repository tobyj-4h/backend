resource "aws_lambda_function" "location_get_districts_lambda" {
  function_name = "LocationGetDistricts"
  handler       = "location-get-districts.handler"
  runtime       = var.lambda_runtime
  role          = aws_iam_role.location_lambda_role.arn

  filename         = "${path.module}/../dist/location-get-districts.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/location-get-districts.zip")

  environment {
    variables = {
      LOG_LEVEL         = "INFO"
      OPENSEARCH_DOMAIN = "https://${aws_opensearch_domain.location.endpoint}"
      INDEX_NAME        = "districts-geo-index"
      REQUIRED_SCOPE    = ""
    }
  }

  timeout = 10
}

resource "aws_cloudwatch_log_group" "location_get_districts_log_group" {
  name              = "/aws/lambda/LocationGetDistrictsFunction"
  retention_in_days = 7
}

resource "aws_lambda_permission" "api_gateway_location_get_districts_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.location_get_districts_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.location_api.execution_arn}/*/*"
}

resource "aws_lambda_function" "location_get_schools_lambda" {
  function_name = "LocationGetSchools"
  handler       = "location-get-schools.handler"
  runtime       = var.lambda_runtime
  role          = aws_iam_role.location_lambda_role.arn

  filename         = "${path.module}/../dist/location-get-schools.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/location-get-schools.zip")

  environment {
    variables = {
      LOG_LEVEL         = "INFO"
      OPENSEARCH_DOMAIN = "https://${aws_opensearch_domain.location.endpoint}"
      INDEX_NAME        = "school-geo-index"
      REQUIRED_SCOPE    = ""
    }
  }

  timeout = 10
}

resource "aws_cloudwatch_log_group" "location_get_schools_log_group" {
  name              = "/aws/lambda/LocationGetSchoolsFunction"
  retention_in_days = 7
}

resource "aws_lambda_permission" "api_gateway_location_get_schools_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.location_get_schools_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.location_api.execution_arn}/*/*"
}

resource "aws_lambda_function" "location_get_geocode_lambda" {
  function_name = "LocationGetGeocode"
  handler       = "location-get-geocode.handler"
  runtime       = var.lambda_runtime
  role          = aws_iam_role.location_lambda_role.arn

  filename         = "${path.module}/../dist/location-get-geocode.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/location-get-geocode.zip")

  environment {
    variables = {
      LOG_LEVEL        = "INFO"
      PLACE_INDEX_NAME = aws_location_place_index.esri_place_index.index_name
      REQUIRED_SCOPE   = ""
    }
  }

  timeout = 10
}

resource "aws_cloudwatch_log_group" "location_get_geocode_log_group" {
  name              = "/aws/lambda/LocationGetGeocodeFunction"
  retention_in_days = 7
}

resource "aws_lambda_permission" "api_gateway_location_get_geocode_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.location_get_geocode_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.location_api.execution_arn}/*/*"
}

resource "aws_lambda_function" "location_authorizer_lambda" {
  function_name = "LocationAuthorizer"
  handler       = "location-authorizer.handler"
  runtime       = var.lambda_runtime
  role          = aws_iam_role.location_lambda_role.arn

  filename         = "${path.module}/../dist/location-authorizer.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/location-authorizer.zip")

  environment {
    variables = {
      LOG_LEVEL    = "INFO"
      USER_POOL_ID = var.user_pool_id
      REGION       = data.aws_region.current.name
    }
  }
}

resource "aws_cloudwatch_log_group" "location_authorizer_log_group" {
  name              = "/aws/lambda/LocationAuthorizerFunction"
  retention_in_days = 7
}
