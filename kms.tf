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