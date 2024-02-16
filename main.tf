terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.45.0"
    }
  }

  required_version = ">= 1.3.6"

  # tfstate stored on S3 
  backend "s3" {
    bucket         = "labzero-terraform-state"
    key            = "iac-s3-demo/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-state-lock-table"
  }
}

provider "aws" {
  default_tags {
    tags = {
      Product = "lz-iac-s3-demo"
    }
  }
}

resource "aws_s3_bucket" "s3_iac_example" {
  bucket = "lz-s3-iac-example"
}

resource "aws_s3_bucket_lifecycle_configuration" "s3_iac_example" {
  bucket = aws_s3_bucket.s3_iac_example.id
  rule {
    id     = "expire"
    status = "Enabled"
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    expiration {
      days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_versioning" "s3_iac_example_versioning" {
  bucket = aws_s3_bucket.s3_iac_example.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "access_s3_iac_example" {
  bucket = aws_s3_bucket.s3_iac_example.id

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

resource "aws_s3_bucket" "log_bucket" {
  bucket = "lz-s3-iac-example-log-bucket"
}

resource "aws_s3_bucket_lifecycle_configuration" "log_bucket" {
  bucket = aws_s3_bucket.log_bucket.id
  rule {
    id     = "expire"
    status = "Enabled"
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    expiration {
      days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_versioning" "log_bucket_versioning" {
  bucket = aws_s3_bucket.log_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "access_log_bucket" {
  bucket = aws_s3_bucket.log_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}


resource "aws_s3_bucket_logging" "s3_iac_bucket_logging" {
  bucket        = aws_s3_bucket.s3_iac_example.id
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/"
}
