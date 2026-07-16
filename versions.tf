terraform {
  # >= 1.7 so the bundled `terraform test` suites (mock_provider) run on the
  # declared floor; upper-bounded to stay within the 1.x line.
  required_version = ">= 1.7.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.44"
    }
  }
}
