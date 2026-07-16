locals {
  # Full resource names compose the label id with the caller's map key, so a
  # group/alarm keyed "app" under label "dvtca-prod-svc" becomes
  # "dvtca-prod-svc-app". A bare id prefix keeps names collision-free per stack.
  name_prefix = local.id != "" ? "${local.id}-" : ""

  log_group_names = { for k in keys(var.log_groups) : k => "${local.name_prefix}${k}" }
  alarm_names     = { for k in keys(var.metric_alarms) : k => "${local.name_prefix}${k}" }
}
