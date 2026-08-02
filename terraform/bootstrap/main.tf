# --- GitHub OIDC provider + roles ---------------------------------------
# Replaces long-lived AWS access keys with short-lived federated credentials.
# Least-privilege per job type: CI role pushes to ECR, CD role deploys to ECS.
module "github_oidc" {
  source      = "../modules/oidc"
  github_repo = var.github_repo
}

module "ecr" {
  source        = "../modules/ecr"
  repo_name     = "vault-forge-app"
  push_role_arn = module.github_oidc.ecr_push_role_arn
}

module "ecs" {
  source          = "../modules/ecs_fargate"
  cluster_name    = var.cluster_name
  deploy_role_arn = module.github_oidc.eks_deploy_role_arn
  aws_region      = var.aws_region
}
