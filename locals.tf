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