variable "azure_location" {
  type    = string
  default = "swedencentral"
}

variable "cluster_name" {
  type    = string
  default = "cloudaura-aks-cluster"
}

variable "resource_group_name" {
  type    = string
  default = "cloudaura-rg"
}

variable "cluster_version" {
  type    = string
  default = "1.31"
}

variable "environment" {
  type    = string
  default = "staging"
}

variable "domain_name" {
  type    = string
  default = "cloudaura.online"
}

variable "cluster_admin_object_id" {
  type        = string
  description = "az ad signed-in-user show --query id -o tsv"
}
