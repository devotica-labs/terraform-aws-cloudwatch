# Integration tests — apply + assert + destroy. Requires real AWS credentials.
# A single log group + a single alarm are cheap and fast to create/destroy, and
# carry no deletion protection so teardown is clean.

provider "aws" {
  region = "ap-south-1"
}

variables {
  namespace = "dvtca"
  stage     = "integ"
  name      = "cw"

  log_groups = {
    app = {}
  }

  metric_alarms = {
    cpu-high = {
      namespace           = "AWS/EC2"
      metric_name         = "CPUUtilization"
      comparison_operator = "GreaterThanThreshold"
      threshold           = 80
      period              = 300
      evaluation_periods  = 2
      statistic           = "Average"
    }
  }

  tags = {
    Environment = "integration-test"
    Ephemeral   = "true"
  }
}

run "apply_and_assert" {
  command = apply

  assert {
    condition     = one([for g in aws_cloudwatch_log_group.this : g.retention_in_days]) == 90
    error_message = "Log group must apply with the 90-day retention default."
  }
  assert {
    condition     = one([for g in aws_cloudwatch_log_group.this : g.arn]) != ""
    error_message = "Log group must be created with an ARN."
  }
  assert {
    condition     = one([for a in aws_cloudwatch_metric_alarm.this : a.arn]) != ""
    error_message = "Metric alarm must be created with an ARN."
  }
}
