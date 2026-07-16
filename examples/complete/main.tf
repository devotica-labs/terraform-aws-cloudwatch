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

# A full monitoring baseline for a payments service: several KMS-encrypted log
# groups with mixed retention, a set of metric alarms wired to an SNS topic, and
# an operational dashboard.
module "cloudwatch" {
  source = "../.."

  namespace = "dvtca"
  stage     = "prod"
  name      = "payments"

  # Customer-managed key encrypts every log group at rest.
  kms_key_arn            = "arn:aws:kms:ap-south-1:111122223333:key/00000000-0000-0000-0000-000000000000"
  default_retention_days = 90

  # Three log groups; the audit trail overrides retention to seven years.
  log_groups = {
    api     = {}
    worker  = { retention_days = 30 }
    audit   = { retention_days = 2557 }
    metrics = { retention_days = 365 }
  }

  # Several alarms, all notifying the ops SNS topic on breach and recovery.
  metric_alarms = {
    api-5xx = {
      namespace           = "AWS/ApplicationELB"
      metric_name         = "HTTPCode_Target_5XX_Count"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 10
      period              = 60
      evaluation_periods  = 3
      statistic           = "Sum"
      alarm_actions       = ["arn:aws:sns:ap-south-1:111122223333:ops-alerts"]
      dimensions          = { LoadBalancer = "app/payments/50dc6c495c0c9188" }
      treat_missing_data  = "notBreaching"
    }
    db-cpu-high = {
      namespace           = "AWS/RDS"
      metric_name         = "CPUUtilization"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 85
      period              = 300
      evaluation_periods  = 3
      statistic           = "Average"
      alarm_actions       = ["arn:aws:sns:ap-south-1:111122223333:ops-alerts"]
      dimensions          = { DBInstanceIdentifier = "payments-prod" }
    }
    queue-depth = {
      namespace           = "AWS/SQS"
      metric_name         = "ApproximateNumberOfMessagesVisible"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 1000
      period              = 300
      evaluation_periods  = 2
      statistic           = "Maximum"
      alarm_actions       = ["arn:aws:sns:ap-south-1:111122223333:ops-alerts"]
      dimensions          = { QueueName = "payments-jobs" }
      treat_missing_data  = "breaching"
    }
  }

  # An operational dashboard rendered from a JSON body.
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "API 5XX"
          region = "ap-south-1"
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", "app/payments/50dc6c495c0c9188"]
          ]
          period = 60
          stat   = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "RDS CPU"
          region = "ap-south-1"
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "payments-prod"]
          ]
          period = 300
          stat   = "Average"
        }
      }
    ]
  })

  tags = {
    Environment = "prod"
    Project     = "terraform-aws-cloudwatch"
    Owner       = "platform@devotica.com"
    CostCenter  = "PLATFORM-OSS"
    ManagedBy   = "Terraform"
    Repo        = "https://github.com/devotica-labs/terraform-aws-cloudwatch"
  }
}
