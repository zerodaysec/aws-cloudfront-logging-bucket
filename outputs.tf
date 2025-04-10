
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