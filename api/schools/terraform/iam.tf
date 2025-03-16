resource "aws_iam_role" "sagemaker_execution_role" {
  name = "SageMakerExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "sagemaker_execution_policy" {
  role = aws_iam_role.sagemaker_execution_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.schools_data_bucket.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.schools_data_bucket.bucket}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_ecr_repository_policy" "allow_sagemaker_pull" {
  repository = aws_ecr_repository.school_district_query_repo.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.sagemaker_execution_role.arn
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      }
    ]
  })
}


resource "aws_iam_role_policy" "sagemaker_ecr_access" {
  role = aws_iam_role.sagemaker_execution_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "arn:aws:ecr:us-east-1:314146313891:repository/school-district-query"
      }
    ]
  })
}

resource "aws_iam_role" "lambda_exec" {
  name = "schools_api_lambda_exec_role"

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

resource "aws_iam_policy" "get_school_by_id_lambda_policy" {
  name = "SchoolsGetByIDLambdaPolicy"
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
        aws_cloudwatch_log_group.get_schools_by_id_log_group.arn,       # Restrict to specific log group
        "${aws_cloudwatch_log_group.get_schools_by_id_log_group.arn}:*" # Allow access to log streams in the group
      ]
      }, {
      Effect = "Allow",
      Action = [
        "dynamodb:GetItem",
        "dynamodb:Query",
        "dynamodb:Scan"
      ],
      Resource = [
        "${aws_dynamodb_table.schools.arn}"
      ]
    }]
  })
}

resource "aws_iam_policy" "get_schools_by_district_lambda_policy" {
  name = "SchoolsGetByDistrictLambdaPolicy"
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
        aws_cloudwatch_log_group.get_schools_by_district_log_group.arn,       # Restrict to specific log group
        "${aws_cloudwatch_log_group.get_schools_by_district_log_group.arn}:*" # Allow access to log streams in the group
      ]
      }, {
      Effect = "Allow",
      Action = [
        "dynamodb:GetItem",
        "dynamodb:Query",
        "dynamodb:Scan"
      ],
      Resource = [
        "${aws_dynamodb_table.schools.arn}",
        "${aws_dynamodb_table.schools.arn}/index/DistrictIndex"
      ]
    }]
  })
}

resource "aws_iam_policy" "get_schools_nearby_lambda_policy" {
  name = "SchoolsGetNearbyLambdaPolicy"
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
        aws_cloudwatch_log_group.get_schools_nearby_log_group.arn,       # Restrict to specific log group
        "${aws_cloudwatch_log_group.get_schools_nearby_log_group.arn}:*" # Allow access to log streams in the group
      ]
      }, {
      Effect = "Allow",
      Action = [
        "dynamodb:GetItem",
        "dynamodb:Query",
        "dynamodb:Scan"
      ],
      Resource = [
        "${aws_dynamodb_table.schools.arn}",
        "${aws_dynamodb_table.schools.arn}/index/DistrictIndex"
      ]
      }, {
      Effect = "Allow",
      Action = [
        "sagemaker:InvokeEndpoint"
      ],
      Resource = "arn:aws:sagemaker:us-east-1:314146313891:endpoint/school-district-query-endpoint-v1-0-9"
      }
    ]
  })
}

##################################################
# Permissions and IAM Policy Attachments
##################################################
resource "aws_iam_role_policy_attachment" "get_school_by_id_lambda_attach_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.get_school_by_id_lambda_policy.arn
}

resource "aws_iam_role_policy_attachment" "get_schools_by_district_lambda_attach_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.get_schools_by_district_lambda_policy.arn
}

resource "aws_iam_role_policy_attachment" "get_schools_nearby_lambda_attach_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.get_schools_nearby_lambda_policy.arn
}
