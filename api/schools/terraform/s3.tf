resource "aws_s3_bucket" "schools_data_bucket" {
  bucket = "parenthub-schools-data-bucket-${var.environment}"

  tags = {
    API = "Schools API"
  }
}

resource "aws_s3_object" "school_districts_parquet_file" {
  bucket = aws_s3_bucket.schools_data_bucket.bucket
  key    = "school_districts.parquet"
  source = "${path.module}/../data/output/school_districts.parquet"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag = filemd5("${path.module}/../data/output/school_districts.parquet")

  lifecycle {
    ignore_changes = [etag] # Ignore changes to etag to avoid redeploying the file unless it's manually changed
  }
}

resource "aws_s3_object" "spatial_index_idx_file" {
  bucket = aws_s3_bucket.schools_data_bucket.bucket
  key    = "spatial_index.idx"
  source = "${path.module}/../data/output/spatial_index.idx"

  etag = filemd5("${path.module}/../data/output/spatial_index.idx")

  lifecycle {
    ignore_changes = [etag] # Ignore changes to etag to avoid redeploying the file unless it's manually changed
  }
}

resource "aws_s3_object" "spatial_index_dat_file" {
  bucket = aws_s3_bucket.schools_data_bucket.bucket
  key    = "spatial_index.dat"
  source = "${path.module}/../data/output/spatial_index.dat"

  etag = filemd5("${path.module}/../data/output/spatial_index.dat")

  lifecycle {
    ignore_changes = [etag] # Ignore changes to etag to avoid redeploying the file unless it's manually changed
  }
}
