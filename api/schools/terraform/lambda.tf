##################################################
# Lambda: Get School By ID
##################################################
resource "aws_lambda_function" "get_school_by_id_lambda" {
  function_name = "SchoolsGetByIDFunction"
  handler       = "get-school-by-id.lambda_handler"
  runtime       = "python3.13"
  role          = aws_iam_role.lambda_exec.arn

  filename         = "${path.module}/../dist/get-school-by-id.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/get-school-by-id.zip")

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.schools.name
    }
  }

  tracing_config {
    mode = "Active"
  }
}

resource "aws_cloudwatch_log_group" "get_schools_by_id_log_group" {
  name              = "/aws/lambda/SchoolsGetByIDFunction"
  retention_in_days = 7
}

resource "aws_lambda_permission" "get_school_by_id_invoke_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_school_by_id_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.schools_api.execution_arn}/*/*"
}

##################################################
# Lambda: Get Schools By District
##################################################
resource "aws_lambda_function" "get_schools_by_district_lambda" {
  function_name = "SchoolsGetByDistrictFunction"
  handler       = "get-schools-by-district.lambda_handler"
  runtime       = "python3.13"
  role          = aws_iam_role.lambda_exec.arn

  filename         = "${path.module}/../dist/get-schools-by-district.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/get-schools-by-district.zip")

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.schools.name
    }
  }

  tracing_config {
    mode = "Active"
  }
}

resource "aws_cloudwatch_log_group" "get_schools_by_district_log_group" {
  name              = "/aws/lambda/SchoolsGetByDistrictFunction"
  retention_in_days = 7
}

resource "aws_lambda_permission" "get_schools_by_district_invoke_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_schools_by_district_lambda.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.schools_api.execution_arn}/*/*"
}

##################################################
# Lambda: Get Schools Nearby
##################################################
resource "aws_lambda_function" "get_schools_nearby_lambda" {
  function_name = "SchoolsGetNearbyFunction"
  handler       = "get-schools-nearby.lambda_handler"
  runtime       = "python3.13"
  role          = aws_iam_role.lambda_exec.arn

  filename         = "${path.module}/../dist/get-schools-nearby.zip"
  source_code_hash = filebase64sha256("${path.module}/../dist/get-schools-nearby.zip")

  environment {
    variables = {
      TABLE_NAME              = aws_dynamodb_table.schools.name
      SAGEMAKER_ENDPOINT_NAME = aws_sagemaker_endpoint.school_district_endpoint_v1_0_9.name
    }
  }

  tracing_config {
    mode = "Active"
  }
}

resource "aws_cloudwatch_log_group" "get_schools_nearby_log_group" {
  name              = "/aws/lambda/SchoolsGetNearbyFunction"
  retention_in_days = 7
}

resource "aws_lambda_permission" "get_schools_nearby_invoke_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_schools_nearby_lambda.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.schools_api.execution_arn}/*/*"
}
