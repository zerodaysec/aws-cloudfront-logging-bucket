#########################
##### variables.tf #####
#########################
variable "bucket_name" {
  description = "The name of the S3 bucket to create. Must be globally unique."
  type        = string
}

# Optionally restrict who can write to the bucket.
# If left empty then any AWS account will be allowed to write objects.
variable "allowed_accounts" {
  description = "List of AWS account IDs allowed to put objects in the bucket. If empty, open to all."
  type        = list(string)
  default     = []
}

# Optionally restrict access by AWS Organization.
# If provided, the bucket policy will include a condition that requires the principal to be part of this org.
variable "allowed_org" {
  description = "AWS Organization ID to restrict principals (e.g. 'o-xxxxxxxx'). Leave empty to disable org-level restriction."
  type        = string
  default     = ""
}

# Enable KMS encryption for the bucket. When set to true, objects are encrypted using AWS KMS.
variable "enable_kms" {
  description = "Boolean to enable KMS encryption for the bucket. If false, AES256 will be used."
  type        = bool
  default     = false
}

# Optionally provide an existing KMS Key ARN.
# If enable_kms is true but this is not provided, the module will create a new KMS key.
variable "kms_key_id" {
  description = "Optional: ARN of an existing KMS key to use for bucket encryption. Leave empty to have one created."
  type        = string
  default     = ""
}

# Owner account ID used for administration of resources (for example, for the KMS key policy).
variable "owner_account_id" {
  description = "AWS Account ID of the owner (used in the KMS key policy)."
  type        = string
}

# Organizational tags: Company, App, Env, Owner, Costcenter etc.
variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default     = {
    Company   = "ExampleCorp"
    App       = "CloudFrontLogging"
    Env       = "Production"
    Owner     = "OpsTeam"
    Costcenter= "1001"
  }
}

#########################
##### locals.tf #########
#########################
locals {
  # Determine the list of allowed principals.
  # If allowed_accounts are provided then convert each account ID to its corresponding ARN.
  allowed_principals = length(var.allowed_accounts) > 0 ? [for acc in var.allowed_accounts: "arn:aws:iam::${acc}:root"] : ["*"]

  # Build the bucket policy statement.
  # The base statement allows s3:PutObject to the bucket.
  # If allowed_org is provided, then add a condition to restrict usage to the given organization.
  bucket_policy = {
    Version   = "2012-10-17"
    Statement = [
      merge(
        {
          Sid       = "AllowPutObject"
          Effect    = "Allow"
          Principal = length(var.allowed_accounts) > 0 ? { AWS = local.allowed_principals } : "*"
          Action    = "s3:PutObject"
          # All objects within the bucket
          Resource  = "${aws_s3_bucket.log_bucket.arn}/*"
        },
        var.allowed_org != "" ? {
          Condition = {
            StringEquals = {
              "aws:PrincipalOrgID" = var.allowed_org
            }
          }
        } : {}
      )
    ]
  }
}

#########################
##### main.tf ###########
#########################
# Create the S3 bucket that will centralize CloudFront logs.
resource "aws_s3_bucket" "log_bucket" {
  bucket = var.bucket_name

  # Enforce best practices: disable public access.
  acl    = "private"

  tags = var.tags

  # Enable a lifecycle rule to transition objects to GLACIER Instant Retrieval after 30 days.
  lifecycle_rule {
    id      = "transition-to-glacier"
    enabled = true

    transition {
      days          = 30
      storage_class = "GLACIER_IR"
    }
  }

  # Prevent accidental deletion of logged data.
  force_destroy = false
}

# Attach the bucket policy to allow object writes based on inputs.
resource "aws_s3_bucket_policy" "log_bucket_policy" {
  bucket = aws_s3_bucket.log_bucket.id
  policy = jsonencode(local.bucket_policy)
}

#########################
##### kms.tf ############
#########################
# Optionally create a KMS key if encryption is enabled and no key was provided.
resource "aws_kms_key" "log_bucket" {
  count               = var.enable_kms && var.kms_key_id == "" ? 1 : 0
  description         = "KMS key for encrypting objects in the logging S3 bucket"
  deletion_window_in_days = 10

  policy = <<EOF
{
  "Id": "key-default-1",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Allow administration of the key",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${var.owner_account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
EOF

  tags = var.tags
}

# Configure bucket encryption using a separate resource.
# When enable_kms is true, use KMS encryption; otherwise, use default AES256 encryption.
resource "aws_s3_bucket_server_side_encryption_configuration" "log_bucket_encryption" {
  bucket = aws_s3_bucket.log_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.enable_kms ? "aws:kms" : "AES256"
      # Only specify kms_master_key_id when using KMS.
      kms_master_key_id = var.enable_kms ? ( var.kms_key_id != "" ? var.kms_key_id : aws_kms_key.log_bucket[0].arn ) : null
    }
  }
}

#########################
##### outputs.tf ########
#########################
output "bucket_arn" {
  description = "ARN of the logging S3 bucket"
  value       = aws_s3_bucket.log_bucket.arn
}

output "bucket_name" {
  description = "Name of the logging S3 bucket"
  value       = aws_s3_bucket.log_bucket.bucket
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for bucket encryption (if created)"
  value       = var.enable_kms ? ( var.kms_key_id != "" ? var.kms_key_id : (length(aws_kms_key.log_bucket) > 0 ? aws_kms_key.log_bucket[0].arn : "") ) : ""
}