

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
