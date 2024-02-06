terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
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


resource "aws_s3_bucket_ownership_controls" "s3_iac_ownership" {
  bucket = aws_s3_bucket.s3_iac_example.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "s3_access" {
  bucket = aws_s3_bucket.s3_iac_example.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_acl" "example" {
  depends_on = [
    aws_s3_bucket_ownership_controls.s3_iac_ownership,
    aws_s3_bucket_public_access_block.s3_access,
  ]

  bucket = aws_s3_bucket.s3_iac_example.id
  acl    = "public-read"
}