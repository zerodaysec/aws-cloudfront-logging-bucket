# Terraform Module: S3 Log Bucket with Optional KMS Encryption and Access Controls

This Terraform module creates an Amazon S3 bucket designed to centralize CloudFront logs. It includes built-in safeguards such as lifecycle management for cost optimizations, encryption options (AES256 or KMS), and flexible access controls that restrict who can write objects into the bucket.

---

## Features

- **Secure S3 Bucket Creation:**  
  Creates an S3 bucket with private access to store logs and prevents accidental deletion.

- **Lifecycle Management:**  
  Configures a lifecycle rule to transition objects to GLACIER Instant Retrieval after 30 days.

- **Flexible Access Controls:**  
  Allows you to specify allowed AWS account IDs or restrict access via an AWS Organization ID. If no restrictions are specified, object write access is open to any principal ("*").

- **Encryption Options:**  
  Choose between using AES256 (default) or AWS KMS-managed encryption. If KMS encryption is enabled and no key is provided, the module automatically creates a new KMS key.

- **Tagging:**  
  Supports adding custom organizational tags to all resources created by the module.

---

## Variables

| Variable Name        | Description | Type  | Default |
|----------------------|-------------|-------|---------|
| **bucket_name**      | The name of the S3 bucket to create. Must be globally unique. | string | - |
| **allowed_accounts** | List of AWS account IDs allowed to put objects in the bucket. If empty, the bucket is open to all accounts. | list(string) | [] |
| **allowed_org**      | AWS Organization ID to restrict principals (e.g. 'o-xxxxxxxx'). Leave empty to disable organization-level restriction. | string | "" |
| **enable_kms**       | Boolean to enable KMS encryption for the bucket. When false, objects are encrypted using AES256. | bool | false |
| **kms_key_id**       | ARN of an existing KMS key to use for bucket encryption. Leave empty to create a new key if enable_kms is true. | string | "" |
| **owner_account_id** | AWS Account ID of the owner (used in the KMS key policy). | string | - |
| **tags**             | A map of tags to add to all resources (e.g., Company, App, Env, Owner, Costcenter). | map(string) | { Company = "ExampleCorp", App = "CloudFrontLogging", Env = "Production", Owner = "OpsTeam", Costcenter = "1001" } |

---

## Module Structure

- **variables.tf:**  
  Contains variable definitions and their descriptions.

- **locals.tf:**  
  Defines local values such as allowed principals and builds a dynamic bucket policy. When an organization ID is provided, the bucket policy enforces it using a condition.

- **main.tf:**  
  Creates the S3 bucket with a lifecycle rule and attaches the bucket policy for object put operations.

- **kms.tf:**  
  Optionally creates a new KMS key (if encryption is enabled and one is not provided) and configures bucket server-side encryption with the appropriate algorithm.

- **outputs.tf:**  
  Exposes important resource attributes such as the bucket ARN, bucket name, and KMS key ARN.

---

## Usage

Below is an example of how to use this Terraform module in your project:

hcl
module "s3_log_bucket" {
  source           = "./path/to/module"  # Replace with the path to the module
  bucket_name      = "my-unique-log-bucket-name"
  allowed_accounts = ["123456789012", "098765432109"]
  allowed_org      = "o-abcdef1234"       # Optional: specify an AWS Organization ID
  enable_kms       = true

# Optionally supply an existing KMS key ARN, or leave empty to have one created

# kms_key_id       = "arn:aws:kms:region:account-id:key/key-id"

  owner_account_id = "123456789012"
  tags = {
    Company    = "MyCompany"
    App        = "CloudFrontLogging"
    Env        = "Production"
    Owner      = "DevOpsTeam"
    Costcenter = "2002"
  }
}

### How It Works

1. **S3 Bucket Creation:**  
   The module provisions an S3 bucket with private ACL and applies a lifecycle rule to transition objects after 30 days.

2. **Policy Enforcement:**  
   A bucket policy is attached to allow `s3:PutObject` actions. The policy conditions depend on whether account IDs or an organization ID are provided.

3. **Encryption Configuration:**  
   - If `enable_kms` is set to true:
     - The module utilizes the provided `kms_key_id`, or
     - It creates a new KMS key configured with a policy that grants administrative privileges to the owner account.
   - Server-side encryption for the bucket is set to either `aws:kms` or `AES256` based on the value of `enable_kms`.

4. **Output Values:**  
   After deployment, the module outputs the ARN of the bucket, the bucket name, and the ARN of the KMS key (if encryption is enabled).

---

## Outputs

| Output Name   | Description |
|---------------|-------------|
| **bucket_arn**| ARN of the logging S3 bucket. |
| **bucket_name**| Name of the logging S3 bucket. |
| **kms_key_arn**| ARN of the KMS key used for bucket encryption (if created or provided). |

---

## Requirements

- Terraform 0.12+
- AWS Provider

---

## License

This module is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## Contributing

Contributions are welcome! Please open issues and submit pull requests for any improvements or bug fixes.

---

## Disclaimer

Use this module at your own risk. Always review and test Terraform code in a controlled environment before deploying to production.

Happy Terraforming!
