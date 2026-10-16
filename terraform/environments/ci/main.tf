# -----------------------------------------------------------------------------
# Provider
# -----------------------------------------------------------------------------
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.env
      ManagedBy   = "terraform"
    }
  }
}

# -----------------------------------------------------------------------------
# Module: CICD (GitHub Actions OIDC)
# -----------------------------------------------------------------------------
module "cicd" {
  source = "../../modules/cicd"

  project          = var.project
  env              = var.env
  github_org       = var.github_org
  github_repo      = var.github_repo
  allowed_branches = var.allowed_branches
}
