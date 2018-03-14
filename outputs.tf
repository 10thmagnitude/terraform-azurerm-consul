output "num_servers" {
  value = "${module.consul_servers.cluster_size}"
}

output "load_balancer_ip_address_servers" {
  value = "${module.consul_servers.load_balancer_ip_address}"
}

# output "load_balancer_ip_address_clients" {
#   value = "${module.consul_clients.load_balancer_ip_address}"
# }

