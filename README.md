# terraform-aws-cloudwatch

[![CI](https://github.com/devotica-labs/terraform-aws-cloudwatch/actions/workflows/ci.yml/badge.svg)](https://github.com/devotica-labs/terraform-aws-cloudwatch/actions/workflows/ci.yml)
[![Release](https://github.com/devotica-labs/terraform-aws-cloudwatch/actions/workflows/release.yml/badge.svg)](https://github.com/devotica-labs/terraform-aws-cloudwatch/actions/workflows/release.yml)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

> Part of the **Devotica** Terraform catalog. Follows the cloudposse module standard (README.yaml-driven docs, the `enabled`/`namespace`/`environment`/`stage`/`name`/`attributes`/`tags`/`label_order` label surface, `examples/complete`, Makefile targets) implemented **natively** — no external naming or build-harness dependencies.

## Introduction

Terraform module for the **Amazon CloudWatch** monitoring baseline: encrypted, retained **log groups**, **metric alarms** wired to alarm actions (typically an SNS topic), and an optional **dashboard**. It is the observability layer the rest of the Devotica catalog emits into.

Defaults are fintech-opinionated: log groups are **KMS-encrypted** when a `kms_key_arn` is supplied and are retained for **90 days** by default (never silently unbounded or unretained); alarms notify their `alarm_actions` on both breach and recovery.

## Usage

```hcl
module "cloudwatch" {
  source  = "devotica-labs/cloudwatch/aws"
  version = "~> 0.1"

  namespace   = "dvtca"
  stage       = "prod"
  name        = "api"          # names → dvtca-prod-api-*
  kms_key_arn = module.kms.key_arn

  log_groups = {
    app = {}                   # 90-day retention default, KMS-encrypted
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
      alarm_actions       = [module.sns_alerts.topic_arn]
    }
  }
}
```

Several log groups with mixed retention plus a dashboard:

```hcl
module "cloudwatch" {
  source  = "devotica-labs/cloudwatch/aws"
  version = "~> 0.1"

  namespace   = "dvtca"
  stage       = "prod"
  name        = "payments"
  kms_key_arn = module.kms.key_arn

  log_groups = {
    api   = {}
    audit = { retention_days = 2557 }   # seven years for the audit trail
  }

  dashboard_body = file("${path.module}/dashboard.json")
}
```

See [`examples/basic`](examples/basic) and [`examples/complete`](examples/complete).

## Defaults that matter

| Setting | Default | Why |
|---------|---------|-----|
| `default_retention_days` | `90` | Logs are retained for auditability but not kept forever by default. |
| `kms_key_arn` | `null` | Supply a CMK to envelope-encrypt log data at rest; null leaves service-default encryption. |
| log-group / alarm names | `<label id>-<key>` | Names compose the label id with the map key, keeping them collision-free per stack. |
| alarm `ok_actions` | = `alarm_actions` | Recovery is announced on the same channel as the breach. |
| `treat_missing_data` | `missing` | Missing data neither breaches nor clears an alarm unless the caller opts in. |
| dashboard | off | A dashboard is created only when `dashboard_body` is set. |

## How this fits the Devotica catalog

Compute and data modules (`terraform-aws-ecs-fargate`, `terraform-aws-lambda`, `terraform-aws-rds`) emit metrics and logs; this module creates the log groups those workloads write to and the alarms that watch their metrics. Point `alarm_actions` at an SNS topic to fan out to email / PagerDuty / chat, and pass `terraform-aws-kms`'s key ARN into `kms_key_arn` to encrypt log data at rest.

## Makefile Targets

```
make fmt       # terraform fmt -recursive
make validate  # terraform init -backend=false && terraform validate
make test      # terraform test (unit + contract; integration needs AWS creds)
make readme    # regenerate the terraform-docs block below
```

<!-- BEGIN_TF_DOCS -->
<!-- terraform-docs regenerates this block via `make readme` / CI. Inputs and
     outputs are documented in variables.tf and outputs.tf. -->
<!-- END_TF_DOCS -->

## License

[Apache 2.0](LICENSE) © Devotica
