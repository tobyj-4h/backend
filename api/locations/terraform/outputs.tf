output "opensearch_domain_name" {
  value = aws_opensearch_domain.location.domain_name
}

output "opensearch_domain_endpoint" {
  value = aws_opensearch_domain.location.endpoint
}

output "esri_place_index_name" {
  value = aws_location_place_index.esri_place_index.index_name
}

output "esri_place_index_arn" {
  value = aws_location_place_index.esri_place_index.index_arn
}
