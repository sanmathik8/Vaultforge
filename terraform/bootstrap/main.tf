# --- GitHub OIDC provider + roles ---------------------------------------
# FIX (review item #1): replaces long-lived AWS access keys with short-lived
# federated credentials. Two separate roles, least-privilege per job type —
# the CI job that pushes images never gets EKS deploy permissions, and vice
# versa.
module "github_oidc" {
  source       = "../modules/oidc"
  github_repo  = var.github_repo
}

module "ecr" {
  source       = "../modules/ecr"
  repo_name    = "vault-forge-app"
  push_role_arn = module.github_oidc.ecr_push_role_arn
}

module "eks" {
  source        = "../modules/eks"
  cluster_name  = var.cluster_name
  deploy_role_arn = module.github_oidc.eks_deploy_role_arn
}
