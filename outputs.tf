output "log_group_arns" {
  description = "Map of log-group key → log group ARN."
  value       = { for k, g in aws_cloudwatch_log_group.this : k => g.arn }
}

output "log_group_names" {
  description = "Map of log-group key → composed log group name."
  value       = { for k, g in aws_cloudwatch_log_group.this : k => g.name }
}

output "alarm_arns" {
  description = "Map of alarm key → metric-alarm ARN."
  value       = { for k, a in aws_cloudwatch_metric_alarm.this : k => a.arn }
}

output "dashboard_arn" {
  description = "ARN of the dashboard (null when dashboard_body is not set)."
  value       = try(aws_cloudwatch_dashboard.this[0].dashboard_arn, null)
}
