#############################################
# Initialize OpenStack provider
#############################################
provider "openstack" {
  domain_name = var.domain_name
  tenant_id   = var.project_id
  user_name   = var.user_name
  password    = var.user_password
  auth_url    = "https://api.selvpc.ru/identity/v3"
  region      = var.region
}
###################################
# Create Flavor
###################################
resource "random_string" "random_name_1" {
  length  = 16
  special = false
}

resource "openstack_compute_flavor_v2" "flavor-node" {
  name      = "node.${var.project_id}-${random_string.random_name_1.result}"
  ram       = "1024"
  vcpus     = "1"
  disk      = "0"
  is_public = "false"
}

###################################
# Get image ID
###################################
data "openstack_images_image_v2" "ubuntu" {
  most_recent = true
  name        = "Ubuntu 18.04 LTS 64-bit"
}
###################################
# Create SSH-key
###################################
resource "openstack_compute_keypair_v2" "terraform_key" {
  name       = "terraform_key-${random_string.random_name_1.result}"
  region     = var.region
  public_key = var.public_key
}

###################################
# Create Network and Subnet
###################################
data "openstack_networking_network_v2" "external_net" {
  name = "external-network"
}

resource "openstack_networking_router_v2" "router_1" {
  name                = "router_1"
  external_network_id = data.openstack_networking_network_v2.external_net.id
}

resource "openstack_networking_router_interface_v2" "router_interface_1" {
  router_id = openstack_networking_router_v2.router_1.id
  subnet_id = openstack_networking_subnet_v2.subnet_1.id
}

resource "openstack_networking_network_v2" "network_1" {
  name = "network_1"
}

resource "openstack_networking_subnet_v2" "subnet_1" {
  network_id      = openstack_networking_network_v2.network_1.id
  name            = "192.168.0.0/24"
  cidr            = "192.168.0.0/24"
  dns_nameservers = ["188.93.16.19", "188.93.17.19"]
}

###################################
# Create port
###################################
resource "openstack_networking_port_v2" "port_1" {
  name       = "node-eth0"
  network_id = openstack_networking_network_v2.network_1.id

  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.subnet_1.id
  }
}

###################################
# Create Volume/Disk
###################################
resource "openstack_blockstorage_volume_v3" "volume_1" {
  name                 = "volume-for-node"
  size                 = var.hdd_size
  image_id             = data.openstack_images_image_v2.ubuntu.id
  volume_type          = var.volume_type
  availability_zone    = var.az_zone
  enable_online_resize = true

  lifecycle {
    ignore_changes = [image_id]
  }
}
###################################
# Create Server
###################################
resource "openstack_compute_instance_v2" "instance_1" {
  name              = "node"
  flavor_id         = openstack_compute_flavor_v2.flavor-node.id
  key_pair          = openstack_compute_keypair_v2.terraform_key.id
  availability_zone = var.az_zone

  network {
    port = openstack_networking_port_v2.port_1.id
  }

  block_device {
    uuid             = openstack_blockstorage_volume_v3.volume_1.id
    source_type      = "volume"
    destination_type = "volume"
    boot_index       = 0
  }

  vendor_options {
    ignore_resize_confirmation = true
  }

}

###################################
# Create floating IP
###################################
resource "openstack_networking_floatingip_v2" "floatingip_1" {
  pool = "external-network"
}

###################################
# Link floating IP to internal IP
###################################
resource "openstack_networking_floatingip_associate_v2" "association_1" {
  port_id     = openstack_networking_port_v2.port_1.id
  floating_ip = openstack_networking_floatingip_v2.floatingip_1.address
}
