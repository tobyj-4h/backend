resource "aws_location_place_index" "esri_place_index" {
  index_name  = "esri-place-index"
  data_source = "Esri" # or "Here" (Choose the provider you prefer)
  description = "Place index for geolocation search"

  # Optional: Tags for organization
  tags = {
    Name = "EsriPlaceIndex"
  }
}
