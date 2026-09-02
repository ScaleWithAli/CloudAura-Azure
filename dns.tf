resource "azurerm_dns_zone" "main" {
  name                = var.domain_name
  resource_group_name = var.resource_group_name
  tags                = local.common_tags
}

data "kubernetes_service" "nginx_ingress" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }
  depends_on = [helm_release.ingress_nginx]
}

resource "azurerm_dns_a_record" "main" {
  name                = "@"
  zone_name           = azurerm_dns_zone.main.name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [data.kubernetes_service.nginx_ingress.status[0].load_balancer[0].ingress[0].ip]
}

resource "azurerm_dns_a_record" "wildcard" {
  name                = "*"
  zone_name           = azurerm_dns_zone.main.name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [data.kubernetes_service.nginx_ingress.status[0].load_balancer[0].ingress[0].ip]
}
