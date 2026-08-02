# Sample failure asset for Checkov IaC Scanner
# Demonstrates unencrypted S3 bucket and open security group rule

resource "aws_s3_bucket" "unencrypted_bucket" {
  bucket = "vaultforge-unencrypted-test-bucket"
  # Missing server_side_encryption_configuration
}

resource "aws_security_group" "open_sg" {
  name        = "open-security-group"
  description = "Allows unrestricted SSH access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
