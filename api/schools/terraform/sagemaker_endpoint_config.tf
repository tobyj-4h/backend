resource "aws_sagemaker_endpoint_configuration" "school_district_endpoint_config_v1_0_9" {
  name = "${var.sagemaker_endpoint_name}-config-v1-0-9"

  production_variants {
    variant_name           = "AllTraffic"
    model_name             = aws_sagemaker_model.school_district_model_v1_0_9.name
    initial_instance_count = 1
    instance_type          = var.sagemaker_instance_type
  }
}
