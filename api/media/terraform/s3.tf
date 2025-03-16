resource "aws_s3_bucket" "media_bucket" {
  bucket        = "beehive-media-${var.environment}"
  force_destroy = true
}

resource "aws_iam_policy" "lambda_s3_policy" {
  name = "BeehiveMediaS3WritePolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ],
        Resource = [
          "arn:aws:s3:::beehive-media-dev/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_s3_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_s3_policy.arn
}

