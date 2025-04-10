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