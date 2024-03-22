# gitops_terraform_demo
GitOps demo using GitHub Actions and Terraform to provision S3 bucket


### AWS Provider

- AWS provider with version pinning
- Backend S3 bucket for state file
- DyanmoDB table for state file locking
- Default tags for provisioned resources

```hcl
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
```

### Initial S3 bucket provisioning.

- Simple provisioned S3 bucket.

```hcl
resource "aws_s3_bucket" "s3_iac_example" {
  bucket = "lz-s3-iac-example"
}
```

### Run Terraform Plan

- Terraform plan to generate speculative plan pre-deploy

~~~text
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_s3_bucket.s3_iac_example will be created
  + resource "aws_s3_bucket" "s3_iac_example" {
      + acceleration_status         = (known after apply)
      + acl                         = (known after apply)
      + arn                         = (known after apply)
      + bucket                      = "lz-s3-iac-example"
      + bucket_domain_name          = (known after apply)
      + bucket_regional_domain_name = (known after apply)
      + force_destroy               = false
      + hosted_zone_id              = (known after apply)
      + id                          = (known after apply)
      + object_lock_enabled         = (known after apply)
      + policy                      = (known after apply)
      + region                      = (known after apply)
      + request_payer               = (known after apply)
      + tags_all                    = {
          + "Product" = "lz-iac-s3-demo"
        }
      + website_domain              = (known after apply)
      + website_endpoint            = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.
~~~

### Checkov scanning

- Run [checkov](https://github.com/bridgecrewio/checkov) static analysis for common misconfigurations

  Potential Misconfiguration Errors

  1. CKV2_AWS_6: (Low) Ensure that S3 bucket has a Public Access block
  2. CKV_AWS_18: (Low) Ensure the S3 bucket has access logging enabled 
  3. CKV_AWS_21: (High) Ensure all data stored in the S3 bucket have versioning enabled
  4. CKV2_AWS_61: (Medium) Ensure that an S3 bucket has a lifecycle configuration
  5. CKV2_AWS_62: (Low) Ensure S3 buckets should have event notifications enabled
  6. CKV_AWS_144: (Low) Ensure that S3 bucket has cross-region replication enabled
  7. CKV_AWS_145: (Low) Ensure that S3 buckets are encrypted with KMS by default


  Let's address issues 1-4.  We will suppress issues 5-7 for the purpose of this demo in the [.checkov.yaml](./.checkov.yaml) file.  You should address these issues depending on your security needs for your S3 resource.

~~~text
terraform scan results:

Passed checks: 5, Failed checks: 7, Skipped checks: 0

Check: CKV_AWS_93: "Ensure S3 bucket policy does not lockout all but root user. (Prevent lockouts needing root account fixes)"
	PASSED for resource: aws_s3_bucket.s3_iac_example
	File: /main.tf:28-30
	Guide: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/s3-policies/bc-aws-s3-24
Check: CKV_AWS_41: "Ensure no hard coded AWS access key and secret key exists in provider"
	PASSED for resource: aws.default
	File: /main.tf:20-26
	Guide: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/secrets-policies/bc-aws-secrets-5
Check: CKV_AWS_20: "S3 Bucket has an ACL defined which allows public READ access."
	PASSED for resource: aws_s3_bucket.s3_iac_example
	File: /main.tf:28-30
	Guide: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/s3-policies/s3-1-acl-read-permissions-everyone
Check: CKV_AWS_57: "S3 Bucket has an ACL defined which allows public WRITE access."
	PASSED for resource: aws_s3_bucket.s3_iac_example
	File: /main.tf:28-30
	Guide: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/s3-policies/s3-2-acl-write-permissions-everyone
Check: CKV_AWS_19: "Ensure all data stored in the S3 bucket is securely encrypted at rest"
	PASSED for resource: aws_s3_bucket.s3_iac_example
	File: /main.tf:28-30
	Guide: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/s3-policies/s3-14-data-encrypted-at-rest
Check: CKV_AWS_18: "Ensure the S3 bucket has access logging enabled"
	FAILED for resource: aws_s3_bucket.s3_iac_example
	File: /main.tf:28-30
	Guide: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/s3-policies/s3-13-enable-logging

		28 | resource "aws_s3_bucket" "s3_iac_example" {
		29 |   bucket = "lz-s3-iac-example"
		30 | }

Check: CKV2_AWS_61: "Ensure that an S3 bucket has a lifecycle configuration"
	FAILED for resource: aws_s3_bucket.s3_iac_example
	File: /main.tf:28-30
	Guide: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-logging-policies/bc-aws-2-61

		28 | resource "aws_s3_bucket" "s3_iac_example" {
		29 |   bucket = "lz-s3-iac-example"
		30 | }

Check: CKV2_AWS_62: "Ensure S3 buckets should have event notifications enabled"
	FAILED for resource: aws_s3_bucket.s3_iac_example
	File: /main.tf:28-30
	Guide: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-logging-policies/bc-aws-2-62

		28 | resource "aws_s3_bucket" "s3_iac_example" {
		29 |   bucket = "lz-s3-iac-example"
		30 | }

Check: CKV2_AWS_6: "Ensure that S3 bucket has a Public Access block"
	FAILED for resource: aws_s3_bucket.s3_iac_example
	File: /main.tf:28-30
	Guide: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-networking-policies/s3-bucket-should-have-public-access-blocks-defaults-to-false-if-the-public-access-block-is-not-attached

		28 | resource "aws_s3_bucket" "s3_iac_example" {
		29 |   bucket = "lz-s3-iac-example"
		30 | }

Check: CKV_AWS_145: "Ensure that S3 buckets are encrypted with KMS by default"
	FAILED for resource: aws_s3_bucket.s3_iac_example
	File: /main.tf:28-30
	Guide: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-general-policies/ensure-that-s3-buckets-are-encrypted-with-kms-by-default

		28 | resource "aws_s3_bucket" "s3_iac_example" {
		29 |   bucket = "lz-s3-iac-example"
		30 | }

Check: CKV_AWS_144: "Ensure that S3 bucket has cross-region replication enabled"
	FAILED for resource: aws_s3_bucket.s3_iac_example
	File: /main.tf:28-30
	Guide: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/aws-general-policies/ensure-that-s3-bucket-has-cross-region-replication-enabled

		28 | resource "aws_s3_bucket" "s3_iac_example" {
		29 |   bucket = "lz-s3-iac-example"
		30 | }

Check: CKV_AWS_21: "Ensure all data stored in the S3 bucket have versioning enabled"
	FAILED for resource: aws_s3_bucket.s3_iac_example
	File: /main.tf:28-30
	Guide: https://docs.prismacloud.io/en/enterprise-edition/policy-reference/aws-policies/s3-policies/s3-16-enable-versioning

		28 | resource "aws_s3_bucket" "s3_iac_example" {
		29 |   bucket = "lz-s3-iac-example"
		30 | }
~~~

### Fixing Misconfigurations

  The following changes address the four S3 misconfigurations.

- CKV2_AWS_6: `aws_s3_bucket_public_access_block`
- CKV_AWS_18: `aws_s3_bucket_logging`
- CKV_AWS_21: `aws_s3_bucket_versioning`
- CKV2_AWS_61: `aws_s3_bucket_lifecycle_configuration`


```hcl
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

resource "aws_s3_bucket_lifecycle_configuration" "s3_iac_example" {
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


resource "aws_s3_bucket_acl" "log_bucket_acl" {
  bucket = aws_s3_bucket.log_bucket.id
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket_logging" "s3_iac_bucket_logging" {
  bucket        = aws_s3_bucket.s3_iac_example.id
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/"
}

```

### GitHub Action 

Using GitHub Action as part of a GitOps flow for validating the terraform configuration files during a Pull Request.

For the PR we will run the two jobs,  `static-analysis-scanning` and then `terraform-plan`.

```yaml
name: pr-builder
run-name: PR Builder
on: pull_request

permissions: read-all
jobs:      
  static-analysis-scanning:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@master
    - name: Checkov Scan
      uses: bridgecrewio/checkov-action@v12
      with:
        output_format: cli
        output_file_path: console      
  terraform-plan:
    needs: static-analysis-scanning
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@master    

    # Configure AWS Credentials to deploy terraform changes onto AWS
    - name: Configure AWS Credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        aws-region: us-west-2
        # This is an assumed role created for GitHub Actions to access the statefile of this terraform project
        role-to-assume: arn:aws:iam::295919900413:role/iac-s3-example-role
        role-session-name: S3IaCExampleRole

    # Terraform Cloud Authentication
    - uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: 1.7.2
        terraform_wrapper: false
    
    - name: Terraform Format
      run: terraform fmt -check
    
    - name: Terraform Init
      run: terraform init
    
    - name: Terraform Plan
      run: terraform plan -out=tfplan
      continue-on-error: true
    
    - name: Upload TF Plan  
      uses: actions/upload-artifact@v4
      with:
        name: tfplan
        path: tfplan
```