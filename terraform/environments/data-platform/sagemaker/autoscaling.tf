resource "aws_appautoscaling_target" "elevenlabs_asr" {
  count = local.is-test ? 0 : 1

  min_capacity       = 1
  max_capacity       = 10
  resource_id        = "endpoint/${aws_sagemaker_endpoint.elevenlabs_asr[0].name}/variant/${aws_sagemaker_endpoint_configuration.elevenlabs_asr[0].production_variants[0].variant_name}"
  scalable_dimension = "sagemaker:variant:DesiredInstanceCount"
  service_namespace  = "sagemaker"
}

resource "aws_appautoscaling_policy" "elevenlabs_asr" {
  count = local.is-test ? 0 : 1

  name               = "${local.deployment_name}-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.elevenlabs_asr[0].resource_id
  scalable_dimension = aws_appautoscaling_target.elevenlabs_asr[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.elevenlabs_asr[0].service_namespace

  target_tracking_scaling_policy_configuration {
    # ElevenLabs recommends six concurrent requests per replica for the -with-aligner model.
    target_value = 6

    predefined_metric_specification {
      predefined_metric_type = "SageMakerVariantConcurrentRequestsPerModelHighResolution"
    }
  }
}
