output "cluster_ip_addresses" {
  value = "${azurerm_network_interface.consul.*.private_ip_address}"
}

output "consul_ui_address" {
  value = "${azurerm_network_interface.consul.0.private_ip_address}"
}

output "consul_http_api_port" {
  value = "${var.http_api_port}"
}
