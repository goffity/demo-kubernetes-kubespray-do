variable "do_token" {
  type = string
}

variable "public_ssh_key_location" {
  type = string
}

variable "private_ssh_key_location" {
  type = string
}

variable "vm_num_of_droplets" {
  // if value of '2' is given, the VM_NAME var will be appended with '-0'
  // for the first server, then the second server with '-1', etc
  default = 1
}

variable "ssh_user" {
  default = "admin"
}
