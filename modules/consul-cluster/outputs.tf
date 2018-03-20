output "cluster_ip_addresses" {
  value = "${azurerm_network_interface.consul.0.private_ip_address}"
}
