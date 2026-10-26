variable "cluster_name" { type = string }
variable "cluster_version" { default = "1.30" }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "node_instance_type" { default = "t3.small" }
variable "desired_size" { default = 1 }
variable "min_size" { default = 1 }
variable "max_size" { default = 2 }

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  vpc_id          = var.vpc_id
  subnet_ids      = var.subnet_ids

  cluster_endpoint_public_access = true
  enable_irsa                    = true

  eks_managed_node_groups = {
    default = {
      min_size       = var.min_size
      max_size       = var.max_size
      desired_size   = var.desired_size
      instance_types = [var.node_instance_type]
      capacity_type  = "SPOT"
    }
  }

  tags = {
    Project     = "awsevt"
    Environment = "staging"
  }
}

output "cluster_name" { value = module.eks.cluster_name }
output "cluster_endpoint" { value = module.eks.cluster_endpoint }
output "oidc_provider_arn" { value = module.eks.oidc_provider_arn }
