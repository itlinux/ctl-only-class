resource "tls_private_key" "gen_avi_key" {
  count     = var.number_of_clusters
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "aws_key_pair" "generated_key" {
  count      = var.number_of_clusters
  key_name   = format("%s-%02d", var.generated_key_name, count.index)
  public_key = tls_private_key.gen_avi_key[count.index].public_key_openssh

}
resource "local_file" "ssh_private_key" {
  count           = var.number_of_clusters
  content         = tls_private_key.gen_avi_key[count.index].private_key_pem
  filename        = format("sshkeys/%s-%02d", var.private_gen_key_pem, count.index)
  file_permission = "0600"
}

