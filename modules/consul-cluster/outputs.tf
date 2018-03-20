output "cluster_ip_addresses" {
  value = "${azurerm_network_interface.consul.*.private_ip_address}"
}
