# vultr terraform
# https://www.vultr.com/api
#
# terraform init
# terraform apply
# terraform destroy

terraform {
  required_providers {
    vultr = {
      source  = "vultr/vultr"
      version = "2.15.1"
    }
  }
}

variable "one_cpu_one_gb_ram" {
  description = "1024 MB RAM,25 GB SSD,1.00 TB BW"
  default     = "vc2-1c-1gb"
}

# Enable API access on VULTR and 
provider "vultr" {
  # export VULTR_API_KEY="Your Vultr API Key"
  # api_key = ""
}

resource "vultr_ssh_key" "my_user" {
  name = "Root SSH key"
  ssh_key = "${file("~/.ssh/id_rsa.pub")}"
}

# fetch the available regions from the API
data "http" "regions" {
  url    = "https://api.vultr.com/v2/plans?type=vc2"
  method = "GET"
}

# randomly pick a region
resource "random_shuffle" "vultr_regions" {
  # plans[0] is vc2-1c-1gb
  input        = jsondecode(data.http.regions.response_body).plans[0].locations
  result_count = 1
}

# Create a new instance
resource "vultr_instance" "my_instance" {
  label  = "my instance"
  region = random_shuffle.vultr_regions.result[0]
  plan   = var.one_cpu_one_gb_ram
  os_id                  = "2076" # Alpine Linux x64
  enable_ipv6            = false
  backups                = "disabled"
  activation_email       = false
  ddos_protection        = false
  ssh_key_ids = ["${vultr_ssh_key.my_user.id}"]
}

# that's your machine IP
output "ip" {
  value = vultr_instance.my_instance.main_ip
}
