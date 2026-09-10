resource "azurerm_virtual_network" "main" {
  name                = "${var.cluster_name}-vnet"
  location            = var.azure_location
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/8"]
  tags                = local.common_tags
}

resource "azurerm_subnet" "main" {
  name                 = "aks-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.1.0.0/16"]
}

resource "azurerm_public_ip" "nat" {
  name                = "${var.cluster_name}-nat-ip"
  location            = var.azure_location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

resource "azurerm_nat_gateway" "main" {
  name                = "${var.cluster_name}-nat"
  location            = var.azure_location
  resource_group_name = var.resource_group_name
  tags                = local.common_tags
}

resource "azurerm_nat_gateway_public_ip_association" "main" {
  nat_gateway_id       = azurerm_nat_gateway.main.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

resource "azurerm_subnet_nat_gateway_association" "main" {
  subnet_id      = azurerm_subnet.main.id
  nat_gateway_id = azurerm_nat_gateway.main.id
}
