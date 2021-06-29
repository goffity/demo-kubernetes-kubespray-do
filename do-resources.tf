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

resource "digitalocean_droplet" "ubuntu-k8s-node" {

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
      "timedatectl set-timezone Asia/Bangkok"
    ]
  }

  provisioner "remote-exec" {
    scripts = [
      "scripts/install-k8s.sh"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sysctl -p",
      "adduser --disabled-password --gecos '' ${var.ssh_user}",
      "usermod -aG admin ${var.ssh_user}",
      "mkdir -p /home/${var.ssh_user}/.ssh",
      "chmod 0700 /home/${var.ssh_user}/.ssh",
      "cp /root/.ssh/authorized_keys /home/${var.ssh_user}/.ssh",
      "chmod 0600 /home/${var.ssh_user}/.ssh/authorized_keys",
      "chown -R ${var.ssh_user}:${var.ssh_user} /home/${var.ssh_user}",
      "sed -i -e '/Defaults\\s\\+env_reset/a Defaults\\texempt_group=admin/' /etc/sudoers",
      "sed -i -e 's/%admin ALL=(ALL) ALL/%admin ALL=NOPASSWD:ALL/g' /etc/sudoers",
      "visudo -cf /etc/sudoers",
      "sed -i -e 's/#PubkeyAuthentication/PubkeyAuthentication/g' /etc/ssh/sshd_config",
      "sed -i -e 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config",
      "/usr/sbin/sshd -t && systemctl reload sshd",
      "rm -rf /root/.ssh"
    ]    
  }
}

resource "digitalocean_project_resources" "k8s_droplet" {
  project = data.digitalocean_project.demo.id
  count   = length(digitalocean_droplet.ubuntu-k8s-node)
  resources = [
    digitalocean_droplet.ubuntu-k8s-node[count.index].urn,
  ]
}

# output "droplet_ubuntu-managed_ip" {
#   value = digitalocean_droplet.ubuntu-managed.ipv4_address
# }

output "droplet_api_ip" {
  value = {
    for droplet in digitalocean_droplet.ubuntu-k8s-node :
    droplet.name => droplet.ipv4_address
  }
}