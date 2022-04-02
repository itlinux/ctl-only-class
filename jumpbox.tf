data "aws_ami" "latest-ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_eip" "jumpbox" {
  count    = var.jumpbox_per_cluster * var.number_of_clusters
  instance = aws_instance.jumpbox[count.index].id
  vpc      = true
}
resource "aws_instance" "jumpbox" {
  count                  = var.jumpbox_per_cluster * var.number_of_clusters
  ami                    = data.aws_ami.latest-ubuntu.id
  instance_type          = "t2.medium"
  key_name               = aws_key_pair.generated_key[floor(count.index / var.jumpbox_per_cluster)].key_name
  vpc_security_group_ids = [aws_security_group.controller[floor(count.index / var.jumpbox_per_cluster)].id]
  subnet_id              = aws_subnet.main[floor(count.index / var.jumpbox_per_cluster)].id
  tags = {
    Name            = format("%s-jumpbox-${var.avi_ver}-%0d", random_id.id[count.index % var.number_of_clusters].hex, count.index)
    owner = var.owner
    dep   = var.department
  }
}
resource "null_resource" "jumpbox-add" {
  count = var.jumpbox_per_cluster * var.number_of_clusters
  provisioner "remote-exec" {
    inline = [
      "sleep 10",
      "echo ${aws_key_pair.generated_key[floor(count.index / var.jumpbox_per_cluster)].public_key} >>~/.ssh/authorized_keys",
      "sudo apt install -y apt-transport-https ca-certificates curl software-properties-common",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable\"",
      "sudo apt -y install docker-ce",
      "sudo systemctl enable --now docker",
      "sudo usermod -aG docker ubuntu",
      "sleep 10",
      "sudo docker run -d --name web -p 80:80 itlinux/nginx-net-tools",
      "sudo docker run -d --name web -p 81:80 itlinux/httpd-orange"
    ]
  }
  connection {
    host        = aws_eip.jumpbox[count.index].public_ip
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.gen_avi_key[floor(count.index / var.jumpbox_per_cluster)].private_key_pem
  }
}
