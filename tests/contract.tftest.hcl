# Contract tests — naming + retention default stay stable across versions.

mock_provider "aws" {}

variables {
  namespace = "dvtca"
  stage     = "test"
  name      = "contract"
}

run "log_group_named_from_label" {
  command = plan
  variables {
    log_groups = {
      app = {}
    }
  }
  assert {
    condition     = one([for g in aws_cloudwatch_log_group.this : g.name]) == "dvtca-test-contract-app"
    error_message = "Log-group name must compose label-id with the map key."
  }
}

run "alarm_named_from_label" {
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
      }
    }
  }
  assert {
    condition     = one([for a in aws_cloudwatch_metric_alarm.this : a.alarm_name]) == "dvtca-test-contract-cpu-high"
    error_message = "Alarm name must compose label-id with the map key."
  }
}

run "default_retention_is_ninety" {
  command = plan
  variables {
    log_groups = {
      app = {}
    }
  }
  assert {
    condition     = one([for g in aws_cloudwatch_log_group.this : g.retention_in_days]) == 90
    error_message = "Contract: default retention is 90 days."
  }
}

run "dashboard_named_from_label" {
  command = plan
  variables {
    dashboard_body = "{\"widgets\":[]}"
  }
  assert {
    condition     = one([for d in aws_cloudwatch_dashboard.this : d.dashboard_name]) == "dvtca-test-contract"
    error_message = "Dashboard name must be the composed label id."
  }
}
