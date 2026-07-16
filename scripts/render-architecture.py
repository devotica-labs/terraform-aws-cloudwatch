#!/usr/bin/env python3
"""Render a module architecture diagram from a Terraform plan JSON.

Reads `terraform show -json plan.binary` (from examples/complete), maps the
module's primary AWS resources to their `diagrams.aws.*` icons, and writes a
single PNG showing what the module provisions, grouped in one labelled cluster.
Supporting resources (policies, attachments, IP sets, features) are folded into
the primary they belong to rather than drawn individually.

Usage:
    python scripts/render-architecture.py <plan.json> <output-path-no-ext>
"""

from __future__ import annotations

import json
import sys
from collections import Counter
from pathlib import Path

from diagrams import Cluster, Diagram, Edge
from diagrams.aws.compute import EC2ContainerRegistry, Lambda
from diagrams.aws.database import Dynamodb
from diagrams.aws.general import General, Users
from diagrams.aws.integration import SNS, SQS
from diagrams.aws.management import Cloudwatch
from diagrams.aws.network import CloudFront, ELB, Route53
from diagrams.aws.security import CertificateManager, Guardduty, IAMRole, KMS, WAF
from diagrams.aws.storage import Backup, S3

# resource type -> (icon class, singular label). Only "primary" resources are
# drawn; anything not listed is treated as supporting and skipped.
PRIMARY = {
    "aws_ecr_repository": (EC2ContainerRegistry, "repository"),
    "aws_acm_certificate": (CertificateManager, "certificate"),
    "aws_route53_zone": (Route53, "hosted zone"),
    "aws_route53_record": (Route53, "record"),
    "aws_cloudfront_distribution": (CloudFront, "distribution"),
    "aws_sqs_queue": (SQS, "queue"),
    "aws_sns_topic": (SNS, "topic"),
    "aws_dynamodb_table": (Dynamodb, "table"),
    "aws_lambda_function": (Lambda, "function"),
    "aws_cloudwatch_log_group": (Cloudwatch, "log group"),
    "aws_cloudwatch_metric_alarm": (Cloudwatch, "alarm"),
    "aws_cloudwatch_dashboard": (Cloudwatch, "dashboard"),
    "aws_backup_vault": (Backup, "vault"),
    "aws_backup_plan": (Backup, "plan"),
    "aws_guardduty_detector": (Guardduty, "detector"),
    "aws_iam_role": (IAMRole, "IAM role"),
    "aws_kms_key": (KMS, "KMS key"),
    "aws_wafv2_web_acl": (WAF, "web ACL"),
    "aws_s3_bucket": (S3, "bucket"),
}
# Modules whose primary resource is reached from the internet — draw Users -> it.
EDGE_TYPES = ("aws_cloudfront_distribution", "aws_route53_zone")


def load_resources(plan_path: Path) -> list[dict]:
    plan = json.loads(plan_path.read_text())
    root = plan.get("planned_values", {}).get("root_module", {})
    out: list[dict] = []

    def walk(mod: dict) -> None:
        out.extend(mod.get("resources", []))
        for child in mod.get("child_modules", []):
            walk(child)

    walk(root)
    return out


def main() -> None:
    if len(sys.argv) != 3:
        sys.exit("usage: render-architecture.py <plan.json> <output-no-ext>")
    plan_path, out = Path(sys.argv[1]), Path(sys.argv[2])
    out.parent.mkdir(parents=True, exist_ok=True)

    counts = Counter(r["type"] for r in load_resources(plan_path))
    primary = [(t, c) for t, c in counts.items() if t in PRIMARY]
    if not primary:
        sys.exit(f"No recognised primary resources in {plan_path} — nothing to render.")

    module = Path.cwd().name  # e.g. terraform-aws-ecr
    graph_attr = {"fontsize": "20", "pad": "0.6", "nodesep": "0.7", "ranksep": "0.8", "bgcolor": "white"}

    with Diagram(f"{module}  ·  examples/complete", filename=str(out), show=False,
                 direction="LR", outformat="png", graph_attr=graph_attr):
        edge_node = None
        # Order primaries by the map's declaration order for a stable layout.
        ordered = [t for t in PRIMARY if t in dict(primary)]
        with Cluster(module, graph_attr={"bgcolor": "#F3F0FB", "pencolor": "#232F3E",
                                         "style": "rounded", "fontcolor": "#232F3E", "fontsize": "15"}):
            nodes = {}
            for t in ordered:
                icon, label = PRIMARY[t]
                n = counts[t]
                nodes[t] = icon(f"{label}{f' ×{n}' if n > 1 else ''}")
            # Light supporting-role edges: KMS encrypts the data/store primaries.
            if "aws_kms_key" in nodes:
                for t in ("aws_dynamodb_table", "aws_sqs_queue", "aws_sns_topic",
                          "aws_backup_vault", "aws_s3_bucket"):
                    if t in nodes:
                        nodes["aws_kms_key"] >> Edge(style="dashed", label="encrypts") >> nodes[t]
            if "aws_iam_role" in nodes and "aws_lambda_function" in nodes:
                nodes["aws_iam_role"] >> Edge(style="dashed", label="assumes") >> nodes["aws_lambda_function"]
            for t in EDGE_TYPES:
                if t in nodes:
                    edge_node = nodes[t]

        if edge_node is not None:
            Users("Internet") >> Edge(color="#232F3E") >> edge_node

    print(f"Rendered {module}: {', '.join(f'{PRIMARY[t][1]}×{counts[t]}' for t in ordered)} -> {out}.png")


if __name__ == "__main__":
    main()
