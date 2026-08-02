variable "cluster_name" { type = string }
variable "deploy_role_arn" { type = string }

# Minimal, cost-conscious EKS cluster — single small managed node group,
# scoped for a portfolio-project workload, not a production fleet.
# Given "AWS credits are limited" constraint: 2x t3.medium, no multi-AZ
# redundancy beyond what EKS requires by default.

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.30"

  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]
      min_size       = 2
      max_size       = 4
      desired_size   = 2
    }
  }

  # Grants the CD-deploy OIDC role kubectl access via aws-auth,
  # scoped to what it needs (no cluster-admin).
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
