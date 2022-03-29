output "avi-controller_public_ip" {
  value = aws_eip.avi-controller[*].public_ip
}
output "jumpbox_public_ip" {
  value = aws_eip.jumpbox[*].public_ip
}
output "avi-controller_private_ip" {
  value = aws_eip.avi-controller[*].private_ip
}
output "avi-controller_public_dns_name" {
  value = aws_eip.avi-controller[*].public_dns
}
output "jumpbox_public_dns_name" {
  value = aws_eip.jumpbox[*].public_dns
}
output "aws_subnet" {
  value = aws_subnet.main[*].tags.Name
}
output "VPC_id" {
  value = aws_vpc.main[*].id
}
output "VPC_Name" {
  value = aws_vpc.main[*].tags.Name
}
