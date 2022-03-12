data "http" "avi_data" {
  url = var.git_raw_url

  request_headers = {
    Accept = "application/json"
  }
}

data "template_file" "userdata" {
  template = data.http.avi_data.body
  vars = {
    password = var.admin_password
  }
}
# locals {
#     userdata = templatefile(data.http.avi_data.body,{
#         password = var.admin_password
#     })
# }

resource "aws_eip" "avi-controller" {
  count    = var.number_of_clusters * var.avi_controller
  instance = aws_instance.avi-controller[count.index].id
  vpc      = true
}

resource "aws_instance" "avi-controller" {
  count = var.avi_controller * var.number_of_clusters
  #user_data = (count.index % var.avi_controller) == 0 ? local.userdata : ""
  user_data              = (count.index % var.avi_controller) == 0 ? data.template_file.userdata.rendered : ""
  ami                    = lookup(var.ami-image, var.region)
  instance_type          = var.image-size
  subnet_id              = aws_subnet.main[floor(count.index / var.avi_controller)].id
  iam_instance_profile   = var.iam_profile
  key_name               = aws_key_pair.generated_key[floor(count.index / var.avi_controller)].key_name
  vpc_security_group_ids = [aws_security_group.controller[floor(count.index / var.avi_controller)].id]
  tags = {
    Name            = format("%s-avi_controller-%0d", random_id.id[count.index % var.avi_controller].hex, count.index)
    dept            = var.department_name
    shutdown_policy = var.shutdown_rules
    owner           = var.owner
  }
}

resource "null_resource" "wait_for_controller" {
  count = length(aws_instance.avi-controller)
  provisioner "local-exec" {
    command = "./wait-for-controller.sh"
    environment = {
      CONTROLLER_ADDRESS = aws_eip.avi-controller[count.index].public_ip
      POLL_INTERVAL      = 45
    }
  }
  depends_on = [
    aws_instance.avi-controller
  ]
}
