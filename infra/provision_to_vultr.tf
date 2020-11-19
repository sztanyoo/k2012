# Usage: export VULTR_API_KEY=12345678; terraform apply

provider "vultr" {
  rate_limit  = 700
  retry_limit = 3
}


resource "vultr_server" "kube_server" {
  plan_id   = "203" # "4096 MB RAM,80 GB SSD,3.00 TB BW"
  region_id = "9" # 24=Paris, 9=Frankfurt
  os_id     = "387"  # 387 for Ubuntu 20.04
  label     = "k8s"
  enable_ipv6     = false
  auto_backup     = false
  ddos_protection = false
  notify_activate = true
  script_id       = vultr_startup_script.kubeadm_installer.id
  ssh_key_ids     = [vultr_ssh_key.kube_ssh_key.id]
  firewall_group_id = vultr_firewall_group.kube_firewall.id
  depends_on = [vultr_startup_script.kubeadm_installer]
}

resource "vultr_startup_script" "kubeadm_installer" {
  name = "kubeadm_installer"
  script = file("install_kubeadm_installer.sh")
}

resource "vultr_firewall_group" "kube_firewall" {
    description = "K8s firewall"
}

resource "vultr_firewall_rule" "kube_firewall_ping" {
    firewall_group_id = vultr_firewall_group.kube_firewall.id
    protocol = "icmp"
    network = "0.0.0.0/0"
}

resource "vultr_firewall_rule" "kube_firewall_all" {
    firewall_group_id = vultr_firewall_group.kube_firewall.id
    protocol = "tcp"
    network = "0.0.0.0/0"
    from_port = 1
    to_port = 65535
}
resource "vultr_ssh_key" "kube_ssh_key" {
  name = "kube_ssh_key"
  ssh_key = file("id_rsa_k2012.pub")
}

output "server_ip" {
  value = vultr_server.kube_server.main_ip
}
