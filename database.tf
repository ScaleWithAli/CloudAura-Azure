locals {
  services = {
    auth    = { postgres = true,  redis = false, needs_jwt = true }
    product = { postgres = true,  redis = true,  needs_jwt = false }
    order   = { postgres = true,  redis = true,  needs_jwt = true }
    notif   = { postgres = false, redis = true,  needs_jwt = false }
  }
}

resource "random_password" "master_db_pass" {
  length  = 24
  special = false
}

resource "random_password" "service_db_pass" {
  for_each = { for k, v in local.services : k => v if v.postgres }
  length   = 16
  special  = false
}

resource "random_password" "jwt_secret" {
  length  = 32
  special = false
}

resource "random_password" "redis_pass" {
  length  = 16
  special = false
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "${var.cluster_name}-postgres"
  resource_group_name    = var.resource_group_name
  location               = var.azure_location
  version                = "16"
  administrator_login    = "admin_user"
  administrator_password = random_password.master_db_pass.result
  sku_name               = "B_Standard_B1ms"
  storage_mb             = 32768
  backup_retention_days  = 7
  zone                   = "1"
  tags                   = local.common_tags
  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_aks" {
  name             = "allow-aks"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "10.0.0.0"
  end_ip_address   = "10.255.255.255"
}

resource "azurerm_managed_redis" "main" {
  name                = "${var.cluster_name}-redis"
  resource_group_name = var.resource_group_name
  location            = var.azure_location
  sku_name            = "Balanced_B1"
  tags                = local.common_tags
  default_database {
    clustering_policy = "OSSCluster"
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                      = "cloudaura-kv"
  resource_group_name       = var.resource_group_name
  location                  = var.azure_location
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  sku_name                  = "standard"
  enable_rbac_authorization = true
  tags                      = local.common_tags
}

resource "azurerm_role_assignment" "kv_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_key_vault_secret" "service_secrets" {
  for_each     = local.services
  name         = "${each.key}-secrets"
  key_vault_id = azurerm_key_vault.main.id

  value = jsonencode(merge(
    each.value.needs_jwt ? { JWT_SECRET = random_password.jwt_secret.result } : {},
    each.value.postgres ? {
      DATABASE_URL = "postgresql://admin_user:${random_password.master_db_pass.result}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/${each.key}_db?sslmode=require"
    } : {},
    each.value.redis ? {
      REDIS_URL = "rediss://:${random_password.redis_pass.result}@${azurerm_managed_redis.main.hostname}:10000"
    } : {}
  ))
}
