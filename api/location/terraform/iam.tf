resource "aws_iam_role" "location_lambda_role" {
  name = "LocationLambdaExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "location_basic_execution" {
  role       = aws_iam_role.location_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_opensearch_access" {
  name = "lambda-opensearch-access"
  role = aws_iam_role.location_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "es:ESHttpGet",
          "es:ESHttpPost",
          "es:ESHttpPut"
        ]
        Resource = "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${aws_opensearch_domain.location.domain_name}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_location_policy" {
  name = "LambdaLocationPolicy"
  role = aws_iam_role.location_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["geo:SearchPlaceIndexForText", "geo:SearchPlaceIndexForPosition"],
        Resource = aws_location_place_index.esri_place_index.index_arn
      }
    ]
  })
}

resource "aws_iam_policy" "location_get_districts_lambda_policy" {
  name = "LocationGetDistrictsPolicy"
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
        aws_cloudwatch_log_group.location_get_districts_log_group.arn,
        "${aws_cloudwatch_log_group.location_get_districts_log_group.arn}:*"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "location_get_districts_lambda_attach_policy" {
  role       = aws_iam_role.location_lambda_role.name
  policy_arn = aws_iam_policy.location_get_districts_lambda_policy.arn
}

resource "aws_iam_policy" "location_get_schools_lambda_policy" {
  name = "LocationGetSchoolsPolicy"
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
        aws_cloudwatch_log_group.location_get_schools_log_group.arn,
        "${aws_cloudwatch_log_group.location_get_schools_log_group.arn}:*"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "location_get_schools_lambda_attach_policy" {
  role       = aws_iam_role.location_lambda_role.name
  policy_arn = aws_iam_policy.location_get_schools_lambda_policy.arn
}

resource "aws_iam_policy" "location_get_geocode_lambda_policy" {
  name = "LocationGetGeocodePolicy"
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
        aws_cloudwatch_log_group.location_get_geocode_log_group.arn,
        "${aws_cloudwatch_log_group.location_get_geocode_log_group.arn}:*"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "location_get_geocode_lambda_attach_policy" {
  role       = aws_iam_role.location_lambda_role.name
  policy_arn = aws_iam_policy.location_get_geocode_lambda_policy.arn
}

resource "aws_iam_policy" "location_authorizer_lambda_policy" {
  name = "LocationAuthorizerPolicy"
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
        aws_cloudwatch_log_group.location_authorizer_log_group.arn,
        "${aws_cloudwatch_log_group.location_authorizer_log_group.arn}:*"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "location_authorizer_lambda_attach_policy" {
  role       = aws_iam_role.location_lambda_role.name
  policy_arn = aws_iam_policy.location_authorizer_lambda_policy.arn
}
