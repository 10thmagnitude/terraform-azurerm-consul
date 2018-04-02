# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "location" {
  description = "The location that the resources will run in (e.g. East US)"
}

variable "resource_group_name" {
  description = "The name of the resource group that the resources for consul will run in"
}

variable "subnet_id" {
  description = "The id of the subnet to deploy the cluster into"
}

variable "image_id" {
  description = "The URL of the Image to run in this cluster. Should be an image that had Consul installed and configured by the install-consul module."
}

variable "key_data" {
  description = "The SSH public key that will be added to SSH authorized_users on the consul instances"
}

variable "gossip_encryption_key" {
  description = "The encryption key for consul to encrypt gossip traffic"
}

variable "allowed_inbound_cidr_blocks" {
  description = "A list of CIDR-formatted IP address ranges from which the Azure Instances will allow connections to Consul"
  type        = "list"
}

variable "tls_key_file_path" {
  description = "A path to the key used by Consul for RPC encrpytion with TLS"
}

variable "tls_cert_file_path" {
  description = "A path to the cert used by Consul for RPC encrpytion with TLS"
}

variable "tls_ca_file_path" {
  description = "A path to the ca used by Consul for RPC encrpytion with TLS"
}

variable "consul_install_path" {
  description = "A path to the directory where consul is installed"
  default     = "/etc/consul.d/"
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------
variable "create_as_server" {
  description = "Start consul agent with -server"
  default     = true
}

variable "instance_size" {
  description = "The size of Azure Instances to run for each node in the cluster (e.g. Standard_A0)."
  default     = "Standard_A1_v2"
}

variable "cluster_prefix" {
  description = "The name of the Consul cluster (e.g. consul-stage). This variable is used to namespace all resources created by this module."
  default     = "consul"
}

variable "computer_name_prefix" {
  description = "The string that the name of each instance in the cluster will be prefixed with"
  default     = "consul"
}

variable "admin_user_name" {
  description = "The name of the administrator user for each instance in the cluster"
  default     = "consuladmin"
}

variable "instance_root_volume_size" {
  description = "Specifies the size of the instance root volume in GB. Default 40GB"
  default     = 40
}

variable "cluster_size" {
  description = "The number of nodes to have in the Consul cluster. We strongly recommended that you use either 3 or 5."
  default     = 3
}

variable "subnet_ids" {
  description = "The subnet IDs into which the Azure Instances should be deployed. We recommend one subnet ID per node in the cluster_size variable. At least one of var.subnet_ids or var.availability_zones must be non-empty."
  type        = "list"
  default     = []
}

variable "allowed_ssh_cidr_blocks" {
  description = "A list of CIDR-formatted IP address ranges from which the Azure Instances will allow SSH connections"
  type        = "list"
  default     = []
}

variable "server_rpc_port" {
  description = "The port used by servers to handle incoming requests from other agents."
  default     = 8300
}

variable "cli_rpc_port" {
  description = "The port used by all agents to handle RPC from the CLI."
  default     = 8400
}

variable "serf_lan_port" {
  description = "The port used to handle gossip in the LAN. Required by all agents."
  default     = 8301
}

variable "serf_wan_port" {
  description = "The port used by servers to gossip over the WAN to other servers."
  default     = 8302
}

variable "http_api_port" {
  description = "The port used by clients to talk to the HTTP API"
  default     = 8500
}

variable "dns_port" {
  description = "The port used to resolve DNS queries."
  default     = 8600
}

variable "ssh_port" {
  description = "The port used for SSH connections"
  default     = 22
}

variable "tags" {
  type        = "map"
  description = "A map of the tags to use on the resources that are deployed with this module."
  default     = {}
}
