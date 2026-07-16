output "log_group_arns" {
  description = "Log-group key → ARN."
  value       = module.cloudwatch.log_group_arns
}

output "alarm_arns" {
  description = "Alarm key → ARN."
  value       = module.cloudwatch.alarm_arns
}

output "dashboard_arn" {
  description = "Dashboard ARN."
  value       = module.cloudwatch.dashboard_arn
}
