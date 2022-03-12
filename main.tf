#
# Create a random id
#
resource "random_id" "id" {
  count       = var.number_of_clusters
  byte_length = 2
}
