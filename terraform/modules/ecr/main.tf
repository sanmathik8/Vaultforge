variable "repo_name" { type = string }
variable "push_role_arn" { type = string }
variable "environment" {
  type    = string
  default = "dev"
}

resource "aws_ecr_repository" "app" {
  name                 = var.repo_name
  image_tag_mutability = "IMMUTABLE" # Prevents tag overwrites so signed image digests remain immutable
  tags = {
    Project     = "VaultForge"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Application = "VaultForge"
  }

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

# Lifecycle policy: expires untagged images after 7 days to eliminate storage waste
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Expire untagged images after 7 days"
      selection = {
        tagStatus   = "untagged"
        countType   = "sinceImagePushed"
        countUnit   = "days"
        countNumber = 7
      }
      action = { type = "expire" }
    }]
  })
}

# Least-privilege resource policy restricting push access strictly to CI push role
resource "aws_ecr_repository_policy" "push_access" {
  repository = aws_ecr_repository.app.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCIPush"
      Effect    = "Allow"
      Principal = { AWS = var.push_role_arn }
      Action = [
        "ecr:PutImage",
        "ecr:UploadLayerPart",
        "ecr:InitiateLayerUpload",
        "ecr:CompleteLayerUpload",
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer"
      ]
    }]
  })
}

output "repository_url" { value = aws_ecr_repository.app.repository_url }
output "repository_arn" { value = aws_ecr_repository.app.arn }
