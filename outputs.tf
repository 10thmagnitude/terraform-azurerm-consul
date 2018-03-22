output "consul_ip_addresses" {
  value = "${module.consul_servers.cluster_ip_addresses}"
}

output "consul_ui_tunnel" {
  value = "ssh -o ProxyCommand='ssh -W %h:%p ${var.admin_user_name}@${data.azurerm_public_ip.bastion.ip_address}' ${var.admin_user_name}@${module.consul_servers.cluster_ip_addresses[0]} -L 127.0.0.1:${module.consul_servers.consul_http_api_port}:localhost:${module.consul_servers.consul_http_api_port}"
}

output "consul_ssh" {
  value = "ssh -o ProxyCommand='ssh -W %h:%p ${var.admin_user_name}@${data.azurerm_public_ip.bastion.ip_address}' ${var.admin_user_name}@${module.consul_servers.cluster_ip_addresses[0]}"
}
