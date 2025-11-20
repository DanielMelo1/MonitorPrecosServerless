variable "aws_region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "github_owner" {
  description = "Dono do repositório GitHub"
  type        = string
}

variable "github_repo" {
  description = "Nome do repositório GitHub"
  type        = string
}

variable "github_branch" {
  description = "Branch do GitHub"
  type        = string
  default     = "main"
}

variable "github_token" {
  description = "Token de acesso do GitHub"
  type        = string
  sensitive   = true
}