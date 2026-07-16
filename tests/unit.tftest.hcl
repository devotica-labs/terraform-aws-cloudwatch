# Plan-only unit tests — no AWS credentials required. Assertions target
# config-set values and resource cardinality, never provider-computed attributes.

mock_provider "aws" {}

variables {
  namespace = "dvtca"
  stage     = "test"
  name      = "unit"
}

run "empty_by_default" {
  command = plan
  assert {
    condition     = length(aws_cloudwatch_log_group.this) == 0
    error_message = "No log groups unless log_groups is supplied."
  }
  assert {
    condition     = length(aws_cloudwatch_metric_alarm.this) == 0
    error_message = "No alarms unless metric_alarms is supplied."
  }
  assert {
    condition     = length(aws_cloudwatch_dashboard.this) == 0
    error_message = "No dashboard unless dashboard_body is set."
  }
}

run "log_group_and_alarm_cardinality" {
  command = plan
  variables {
    log_groups = {
      app    = {}
      worker = {}
      audit  = {}
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
      mem-high = {
        namespace           = "CWAgent"
        metric_name         = "mem_used_percent"
        comparison_operator = "GreaterThanThreshold"
        threshold           = 90
        period              = 300
        evaluation_periods  = 2
        statistic           = "Average"
      }
    }
  }
  assert {
    condition     = length(aws_cloudwatch_log_group.this) == 3
    error_message = "One log group per log_groups entry."
  }
  assert {
    condition     = length(aws_cloudwatch_metric_alarm.this) == 2
    error_message = "One alarm per metric_alarms entry."
  }
}

run "retention_default_applied" {
  command = plan
  variables {
    log_groups = {
      app = {}
    }
  }
  assert {
    condition     = one([for g in aws_cloudwatch_log_group.this : g.retention_in_days]) == 90
    error_message = "Log groups without retention_days must inherit the 90-day default."
  }
}

run "retention_override_applied" {
  command = plan
  variables {
    default_retention_days = 90
    log_groups = {
      audit = { retention_days = 365 }
    }
  }
  assert {
    condition     = one([for g in aws_cloudwatch_log_group.this : g.retention_in_days]) == 365
    error_message = "Per-group retention_days must override the default."
  }
}

run "kms_key_applied_to_log_groups" {
  command = plan
  variables {
    kms_key_arn = "arn:aws:kms:ap-south-1:111122223333:key/00000000-0000-0000-0000-000000000000"
    log_groups = {
      app = {}
    }
  }
  assert {
    condition     = one([for g in aws_cloudwatch_log_group.this : g.kms_key_id]) == "arn:aws:kms:ap-south-1:111122223333:key/00000000-0000-0000-0000-000000000000"
    error_message = "kms_key_arn must be applied as the log-group KMS key."
  }
}

run "alarm_config_passthrough" {
  command = plan
  variables {
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
  }
  assert {
    condition     = one([for a in aws_cloudwatch_metric_alarm.this : a.comparison_operator]) == "GreaterThanThreshold"
    error_message = "comparison_operator must pass through unchanged."
  }
  assert {
    condition     = one([for a in aws_cloudwatch_metric_alarm.this : a.threshold]) == 80
    error_message = "threshold must pass through unchanged."
  }
  assert {
    condition     = one([for a in aws_cloudwatch_metric_alarm.this : a.treat_missing_data]) == "missing"
    error_message = "treat_missing_data must default to missing."
  }
  assert {
    condition     = contains(one([for a in aws_cloudwatch_metric_alarm.this : a.alarm_actions]), "arn:aws:sns:ap-south-1:111122223333:ops-alerts")
    error_message = "alarm_actions must be wired to the supplied ARNs."
  }
}

run "dashboard_only_when_body_set" {
  command = plan
  variables {
    dashboard_body = "{\"widgets\":[]}"
  }
  assert {
    condition     = length(aws_cloudwatch_dashboard.this) == 1
    error_message = "A dashboard must be created when dashboard_body is set."
  }
}
