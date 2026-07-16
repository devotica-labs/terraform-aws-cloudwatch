# The monitoring baseline: encrypted, retained log groups + metric alarms wired
# to alarm actions (e.g. an SNS topic), plus an optional dashboard. Fintech
# defaults: KMS encryption when kms_key_arn is set and a 90-day retention floor
# so logs are never silently unbounded or unretained.
resource "aws_cloudwatch_log_group" "this" {
  for_each = local.enabled ? var.log_groups : {}

  name              = local.log_group_names[each.key]
  retention_in_days = coalesce(each.value.retention_days, var.default_retention_days)
  kms_key_id        = var.kms_key_arn

  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "this" {
  for_each = local.enabled ? var.metric_alarms : {}

  alarm_name          = local.alarm_names[each.key]
  namespace           = each.value.namespace
  metric_name         = each.value.metric_name
  comparison_operator = each.value.comparison_operator
  threshold           = each.value.threshold
  period              = each.value.period
  evaluation_periods  = each.value.evaluation_periods
  statistic           = each.value.statistic
  alarm_actions       = each.value.alarm_actions
  ok_actions          = each.value.alarm_actions
  dimensions          = each.value.dimensions
  treat_missing_data  = each.value.treat_missing_data

  tags = local.tags
}

resource "aws_cloudwatch_dashboard" "this" {
  count = local.enabled && var.dashboard_body != null ? 1 : 0

  dashboard_name = local.id
  dashboard_body = var.dashboard_body
}
