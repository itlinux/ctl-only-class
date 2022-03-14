variable "trusted_cidr" {
  description = "cidr block of addresses trusted for access to the kubernetes API server"
}
variable "number_of_clusters" {
  description = "This will be used as an Avi Controller count as well"
  default     = 2
}
variable "avi_controller" {
  default = 2
}
variable "availability_zone" {
  default = "us-west-1a"
}
#region and az need to match
variable "region" {
  default = "us-west-1"
}

variable "generated_key_name" {
  type        = string
  default     = "ctl-k8s-genkey"
  description = "Keypair gen by Terraform"
}

variable "owner" {
  default = "Remo Mattei"
}
variable "private_gen_key_pem" {
}

#### Avi
variable "git_raw_url" {
  description = "The raw URL from the git which contains the json data"
}
variable "admin_password" {
  description = "Admin Password"
}
variable "shutdown_rules" {
  default = "noshut"
}
variable "department_name" {
  default = "FSA TEAM"
}
variable "iam_profile" {
  default = "remo-avi-controller"
}
variable "image-size" {
  description = "Image size"
  default     = "m4.2xlarge"
}
variable "ami-image" {
  default = {
    us-west-1 = "ami-0203558b1728838f9" # 21.1.3
    #us-west-1 = "ami-03baad459ee4a3980"
    #us-west-2 =  "ami-04d08b852b47a5876"   # ami-0ab212620dcc8021b"
    #us-west-2 =  "ami-0451e26f70764fc9e"   # ami-0ab212620dcc8021b"
    #us-west-2 = "ami-17ba2e6f"
  }
}
variable "base_cidr_block" {
  default = "10.0.0.0/16"
}
variable "sg_ports" {
  type        = list(number)
  description = "list of ingress ports"
  default     = [22, 443,80, 8443, 123]
}

