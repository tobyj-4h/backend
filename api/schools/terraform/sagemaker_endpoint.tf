resource "aws_sagemaker_endpoint" "school_district_endpoint_v1_0_8" {
  name                 = "${var.sagemaker_endpoint_name}-v1-0-8"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.school_district_endpoint_config_v1_0_8.name
}

resource "aws_sagemaker_endpoint" "school_district_endpoint_v1_0_9" {
  name                 = "${var.sagemaker_endpoint_name}-v1-0-9"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.school_district_endpoint_config_v1_0_9.name
}
