terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.3.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

# resource "digitalocean_ssh_key" "default" {
#   name       = "k8s-ssh-key"
#   public_key = file(var.public_ssh_key_location)
# }

data "digitalocean_ssh_key" "my_ssh_key" {
  name = "goffity-macbook-pro"
}

data "digitalocean_project" "demo" {
  name = "demo"
}

resource "digitalocean_droplet" "ubuntu-managed" {

  image              = "ubuntu-20-04-x64"
  name               = "ubuntu-k8s-managed"
  region             = "sgp1"
  size               = "s-2vcpu-2gb"
  private_networking = true
  # ssh_keys           = [digitalocean_ssh_key.default.fingerprint]
  ssh_keys = [data.digitalocean_ssh_key.my_ssh_key.id]

  connection {
    user        = "root"
    type        = "ssh"
    host        = self.ipv4_address
    private_key = file(var.private_ssh_key_location)
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      "timedatectl set-timezone Asia/Bangkok",
    ]
  }

  provisioner "remote-exec" {
    scripts = [
      "scripts/install-k8s-managed.sh"
    ]
  }
}

resource "digitalocean_droplet" "ubuntu-node" {

  count = var.vm_num_of_droplets

  image              = "ubuntu-20-04-x64"
  name               = "ubuntu-k8s-${count.index}"
  region             = "sgp1"
  size               = "s-2vcpu-2gb"
  private_networking = true
  # ssh_keys           = [digitalocean_ssh_key.default.fingerprint]
  ssh_keys = [data.digitalocean_ssh_key.my_ssh_key.id]

  connection {
    user        = "root"
    type        = "ssh"
    host        = self.ipv4_address
    private_key = file(var.private_ssh_key_location)
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      "timedatectl set-timezone Asia/Bangkok",
    ]
  }

  provisioner "remote-exec" {
    scripts = [
      "scripts/install-k8s.sh"
    ]
  }
}

resource "digitalocean_project_resources" "k8s_droplet" {
  project = data.digitalocean_project.demo.id
  count   = length(digitalocean_droplet.ubuntu-node)
  resources = [
    digitalocean_droplet.ubuntu-node[count.index].urn,
  ]
}

output "droplet_ubuntu-managed_ip" {
  value = digitalocean_droplet.ubuntu-managed.ipv4_address
}

output "droplet_api_ip" {
  value = {
    for droplet in digitalocean_droplet.ubuntu-node :
    droplet.name => droplet.ipv4_address
  }
}