# Changelog

All notable changes to this module are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the module
follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Releases are cut automatically by `release-please` on merge to `main`,
driven by Conventional Commit prefixes (`feat:` → minor, `fix:`/`docs:`/`chore:` → patch,
`feat!:`/`BREAKING CHANGE:` → major).

## 0.1.0 (2026-07-16)


### Features

* **ci:** add architecture-diagram workflow + renderer ([0fada64](https://github.com/devotica-labs/terraform-aws-cloudwatch/commit/0fada64ad1def9807e5aeabda208eadb97beecdc))
* initial release of terraform-aws-cloudwatch ([f43b597](https://github.com/devotica-labs/terraform-aws-cloudwatch/commit/f43b59798555bbf11930b00aa6909da5a6734594))


### Bug Fixes

* **ci:** drop dead pip/scripts dependabot entry; tflint clean ([e940e77](https://github.com/devotica-labs/terraform-aws-cloudwatch/commit/e940e775b9a5937703c935308473c99068a10fa4))

## [Unreleased]

### Added

- Initial release: the Amazon CloudWatch monitoring baseline — KMS-encrypted,
  retained log groups (`log_groups`, per-group retention override, 90-day
  default), metric alarms wired to `alarm_actions` on breach and recovery
  (`metric_alarms`), and an optional dashboard rendered from `dashboard_body`.
  Native `label.tf` naming (resource names compose the label id with each map
  key); built natively from the AWS provider docs.
