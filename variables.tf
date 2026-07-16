# ---------------------------------------------------------------------------
# Encryption + retention
# ---------------------------------------------------------------------------
variable "kms_key_arn" {
  type        = string
  description = "Customer-managed KMS key ARN used to encrypt every log group. Null (default) leaves log groups on the CloudWatch service-default encryption. Supply a CMK for envelope encryption of log data at rest."
  default     = null

  validation {
    condition     = var.kms_key_arn == null || can(regex("^arn:aws[a-z-]*:kms:", var.kms_key_arn))
    error_message = "kms_key_arn must be a KMS ARN (arn:aws*:kms:...) or null."
  }
}

variable "default_retention_days" {
  type        = number
  description = "Retention applied to any log group that does not set its own retention_days. Fintech default is 90 days so logs are retained but not unbounded. Must be a CloudWatch-supported retention value."
  default     = 90

  validation {
    condition = contains(
      [1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653],
      var.default_retention_days
    )
    error_message = "default_retention_days must be one of the CloudWatch-supported values (1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653)."
  }
}

# ---------------------------------------------------------------------------
# Log groups
# ---------------------------------------------------------------------------
variable "log_groups" {
  type = map(object({
    retention_days = optional(number)
  }))
  description = "Log groups to create, keyed by a short suffix. The full log-group name composes the label id with the key (e.g. \"app\" → \"dvtca-prod-svc-app\"). Set retention_days per group to override default_retention_days; omit it to inherit the default. Every group is KMS-encrypted when kms_key_arn is set."
  default     = {}
}

# ---------------------------------------------------------------------------
# Metric alarms
# ---------------------------------------------------------------------------
variable "metric_alarms" {
  type = map(object({
    namespace           = string
    metric_name         = string
    comparison_operator = string
    threshold           = number
    period              = number
    evaluation_periods  = number
    statistic           = string
    alarm_actions       = optional(list(string), [])
    dimensions          = optional(map(string), {})
    treat_missing_data  = optional(string, "missing")
  }))
  description = "Metric alarms to create, keyed by a short suffix. alarm_actions receives the ARNs notified on breach and recovery (e.g. an SNS topic). dimensions scopes the metric (e.g. { InstanceId = \"i-abc\" }). treat_missing_data defaults to \"missing\"."
  default     = {}

  validation {
    condition = alltrue([
      for a in values(var.metric_alarms) : contains(
        ["GreaterThanOrEqualToThreshold", "GreaterThanThreshold", "LessThanThreshold", "LessThanOrEqualToThreshold", "LessThanLowerOrGreaterThanUpperThreshold", "LessThanLowerThreshold", "GreaterThanUpperThreshold"],
        a.comparison_operator
      )
    ])
    error_message = "Each metric_alarms comparison_operator must be a valid CloudWatch comparison operator."
  }

  validation {
    condition = alltrue([
      for a in values(var.metric_alarms) : contains(
        ["missing", "ignore", "breaching", "notBreaching"],
        a.treat_missing_data
      )
    ])
    error_message = "Each metric_alarms treat_missing_data must be one of: missing, ignore, breaching, notBreaching."
  }
}

# ---------------------------------------------------------------------------
# Dashboard
# ---------------------------------------------------------------------------
variable "dashboard_body" {
  type        = string
  description = "JSON body of a CloudWatch dashboard. When set (non-null), a dashboard named after the label id is created. Null (default) creates no dashboard."
  default     = null

  validation {
    condition     = var.dashboard_body == null || can(jsondecode(var.dashboard_body))
    error_message = "dashboard_body must be null or a valid JSON string."
  }
}
