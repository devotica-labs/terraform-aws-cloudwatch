output "log_group_names" {
  description = "Log-group key → composed name."
  value       = module.cloudwatch.log_group_names
}

output "alarm_arns" {
  description = "Alarm key → ARN."
  value       = module.cloudwatch.alarm_arns
}
