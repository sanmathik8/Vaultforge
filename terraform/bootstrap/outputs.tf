output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "ecs_service_name" {
  value = module.ecs.service_name
}

output "alb_dns_name" {
  value = module.ecs.alb_dns_name
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
