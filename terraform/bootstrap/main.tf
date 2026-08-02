# --- GitHub OIDC provider + roles ---------------------------------------
module "github_oidc" {
  source      = "../modules/oidc"
  github_repo = var.github_repo
}

module "ecr" {
  source        = "../modules/ecr"
  repo_name     = "vault-forge-app"
  push_role_arn = module.github_oidc.ecr_push_role_arn
  environment   = var.environment
}

module "ecs" {
  source          = "../modules/ecs_fargate"
  cluster_name    = var.cluster_name
  deploy_role_arn = module.github_oidc.eks_deploy_role_arn
  aws_region      = var.aws_region
  environment     = var.environment
}
