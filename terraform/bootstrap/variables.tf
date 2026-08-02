variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "cluster_name" {
  type    = string
  default = "vault-forge"
}

variable "github_repo" {
  description = "org/repo allowed to assume the CI/CD OIDC roles"
  type        = string
  default     = "sanmathik8/Vaultforge"
}
