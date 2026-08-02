output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "ci_push_role_arn" {
  value = module.github_oidc.ecr_push_role_arn
}

output "cd_deploy_role_arn" {
  value = module.github_oidc.eks_deploy_role_arn
}

output "terraform_role_arn" {
  value = module.github_oidc.terraform_role_arn
}
