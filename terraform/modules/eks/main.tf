variable "cluster_name" { type = string }
variable "deploy_role_arn" { type = string }

# Fetch Default AWS VPC and Subnets
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Cost-conscious, production-hardened EKS cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.30"

  vpc_id                         = data.aws_vpc.default.id
  subnet_ids                     = data.aws_subnets.default.ids
  cluster_endpoint_public_access = true

  # Production Control Plane Audit Logging
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]
      min_size       = 2
      max_size       = 4
      desired_size   = 2
      ebs_optimized  = true
    }
  }

  # Least-privilege access entry mapping CD OIDC role to namespace-scoped edit policy
  access_entries = {
    cd_deploy = {
      principal_arn = var.deploy_role_arn
      policy_associations = {
        deploy = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
          access_scope = {
            type       = "namespace"
            namespaces = ["vault-forge"]
          }
        }
      }
    }
  }
}

output "cluster_name" { value = module.eks.cluster_name }
output "cluster_arn" { value = module.eks.cluster_arn }
