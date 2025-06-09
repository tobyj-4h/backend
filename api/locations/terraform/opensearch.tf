resource "aws_opensearch_domain" "location" {
  domain_name    = "school-district-geo-index"
  engine_version = "OpenSearch_2.11"

  cluster_config {
    instance_type          = "t3.small.search"
    instance_count         = 1
    zone_awareness_enabled = false
  }

  ebs_options {
    ebs_enabled = true
    volume_type = "gp2"
    volume_size = 10
  }

  access_policies = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.lambda_exec.arn
        }
        Action   = "es:*"
        Resource = "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/school-district-geo-index/*"
      },
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "es:*"
        Resource  = "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/school-district-geo-index/*"
        Condition = {
          IpAddress = {
            "aws:SourceIp" = "74.102.120.248/32"
          }
        }
      }
    ]
  })

  advanced_security_options {
    enabled                        = false
    internal_user_database_enabled = false
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  tags = {
    Name    = "school-district-geo-index"
    Purpose = "Geospatial Lookup for Schools and Districts"
  }
}
