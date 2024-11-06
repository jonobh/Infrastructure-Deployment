variable "project" {
  type        = string
  description = "Project name, i.e. appdeployment"
}

variable "environment" {
  type        = string
  description = "Environment name i.e. dev, prod etc."
}

variable "location" {
  type        = string
  description = "Location of the Azure resources i.e. westeurope "
}

variable "acr_name" {
  type = string
  description = "Name of Azure Container Registry for this environment - must be unique"
}

variable "alert_email" {
  type = string
  description = "Email address associated with container app monitoring alerts"
}

# Local variables
locals {
  tags = {
    Project     = var.project
    Environment = var.environment
  }
}
