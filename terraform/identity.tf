resource "azurerm_user_assigned_identity" "image_updater" {
  name                = "argocd-image-updater-identity"
  resource_group_name = var.resource_group_name
  location            = var.azure_location
  tags                = local.common_tags
}

resource "azurerm_role_assignment" "image_updater_acr" {
  principal_id         = azurerm_user_assigned_identity.image_updater.principal_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.main.id
}

resource "azurerm_federated_identity_credential" "image_updater" {
  name                      = "argocd-image-updater-federated"
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = azurerm_kubernetes_cluster.main.oidc_issuer_url
  user_assigned_identity_id = azurerm_user_assigned_identity.image_updater.id
  subject                   = "system:serviceaccount:argocd:argocd-image-updater-sa"
}

resource "azurerm_user_assigned_identity" "external_secrets" {
  name                = "external-secrets-identity"
  resource_group_name = var.resource_group_name
  location            = var.azure_location
  tags                = local.common_tags
}

resource "azurerm_federated_identity_credential" "external_secrets" {
  name                      = "external-secrets-federated"
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = azurerm_kubernetes_cluster.main.oidc_issuer_url
  user_assigned_identity_id = azurerm_user_assigned_identity.external_secrets.id
  subject                   = "system:serviceaccount:external-secrets:external-secrets-sa"
}

resource "azurerm_role_assignment" "external_secrets_keyvault" {
  principal_id         = azurerm_user_assigned_identity.external_secrets.principal_id
  role_definition_name = "Key Vault Secrets User"
  scope                = azurerm_key_vault.main.id
}

resource "kubernetes_service_account" "external_secrets_sa" {
  metadata {
    name      = "external-secrets-sa"
    namespace = "external-secrets"
    annotations = {
      "azure.workload.identity/client-id" = azurerm_user_assigned_identity.external_secrets.client_id
    }
  }
}
