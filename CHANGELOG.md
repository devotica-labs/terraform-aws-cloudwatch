# Changelog

All notable changes to this module are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the module
follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Releases are cut automatically by `release-please` on merge to `main`,
driven by Conventional Commit prefixes (`feat:` → minor, `fix:`/`docs:`/`chore:` → patch,
`feat!:`/`BREAKING CHANGE:` → major).

## [Unreleased]

### Added

- Initial release: the Amazon CloudWatch monitoring baseline — KMS-encrypted,
  retained log groups (`log_groups`, per-group retention override, 90-day
  default), metric alarms wired to `alarm_actions` on breach and recovery
  (`metric_alarms`), and an optional dashboard rendered from `dashboard_body`.
  Native `label.tf` naming (resource names compose the label id with each map
  key); built natively from the AWS provider docs.
