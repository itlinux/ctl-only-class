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
  count    = var.number_of_clusters * var.jumpbox_per_cluster
  instance = aws_instance.jumpbox[count.index].id
  vpc      = true
}
resource "aws_instance" "jumpbox" {
  count                  = var.number_of_clusters * var.jumpbox_per_cluster
  ami                    = data.aws_ami.latest-ubuntu.id
  instance_type          = var.jumpbox_flavor
  key_name               = aws_key_pair.generated_key[floor(count.index / var.avi_controller)].key_name
  vpc_security_group_ids = [aws_security_group.controller[floor(count.index / var.avi_controller)].id]
  subnet_id              = aws_subnet.main[floor(count.index / var.avi_controller)].id 
  tags                   = {
    Name            = format("%s-jumpbox-${var.avi_ver}-%0d", random_id.id[count.index % var.avi_controller].hex, count.index)
    owner = var.owner
    Dep   = var.department
  }
}
