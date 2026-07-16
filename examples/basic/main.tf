# ---------------------------------------------------------------------------
# Provider block — CI-friendly skip flags + non-AWS-shaped placeholder creds.
# ---------------------------------------------------------------------------
provider "aws" {
  region                      = "ap-south-1"
  access_key                  = "not-a-real-aws-key"
  secret_key                  = "not-a-real-aws-secret"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}

# Uses local path during development.
# Change to Registry source after first release:
#   source  = "devotica-labs/cloudwatch/aws"
#   version = "~> 0.1"

module "cloudwatch" {
  source = "../.."

  # Names compose to: dvtca-sandbox-api-*
  namespace = "dvtca"
  stage     = "sandbox"
  name      = "api"

  # One KMS-encrypted log group at the 90-day retention default.
  kms_key_arn = "arn:aws:kms:ap-south-1:111122223333:key/00000000-0000-0000-0000-000000000000"

  log_groups = {
    app = {}
  }

  # One alarm: EC2 CPU over 80% for two 5-minute periods → notify an SNS topic.
  metric_alarms = {
    cpu-high = {
      namespace           = "AWS/EC2"
      metric_name         = "CPUUtilization"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 80
      period              = 300
      evaluation_periods  = 2
      statistic           = "Average"
      alarm_actions       = ["arn:aws:sns:ap-south-1:111122223333:ops-alerts"]
    }
  }

  tags = {
    Environment = "sandbox"
    Project     = "terraform-aws-cloudwatch"
    Owner       = "platform@devotica.com"
    CostCenter  = "PLATFORM-OSS"
    ManagedBy   = "Terraform"
    Repo        = "https://github.com/devotica-labs/terraform-aws-cloudwatch"
  }
}
