variable "repo_name" { type = string }
variable "push_role_arn" { type = string }

resource "aws_ecr_repository" "app" {
  name                 = var.repo_name
  image_tag_mutability = "IMMUTABLE"   # required so Cosign/Kyverno digest verification can't be bypassed by tag reuse

  image_scanning_configuration {
    scan_on_push = true
  }
}

# FIX (review item #6): lifecycle policy to avoid runaway storage costs
# against limited AWS credits — expires untagged images after 7 days.
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

resource "aws_ecr_repository_policy" "push_access" {
  repository = aws_ecr_repository.app.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCIPush"
      Effect    = "Allow"
      Principal = { AWS = var.push_role_arn }
      Action    = ["ecr:PutImage", "ecr:UploadLayerPart", "ecr:InitiateLayerUpload", "ecr:CompleteLayerUpload", "ecr:BatchCheckLayerAvailability"]
    }]
  })
}

output "repository_url" { value = aws_ecr_repository.app.repository_url }
