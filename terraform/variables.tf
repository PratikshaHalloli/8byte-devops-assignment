variable "aws_region" {
  default = "us-east-1"
}

variable "environment" {
  default = "staging"
}

variable "db_password" {
  default   = "SecurePassword123!"
  sensitive = true
}
