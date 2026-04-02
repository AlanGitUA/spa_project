# ============================================================
# Variables - Innovatech Chile POC
# ============================================================

variable "key_name" {
  description = "Nombre del Key Pair en AWS para acceso SSH"
  type        = string
  default     = "innovatech-key"
}

variable "aws_region" {
  description = "Region de AWS"
  type        = string
  default     = "us-east-1"
}
