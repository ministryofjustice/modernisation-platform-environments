resource "aws_oam_sink" "monitoring_account_oam_sink" {
  name = "HMPPSOemSink"
}

resource "aws_oam_sink_policy" "monitoring_account_oam_sink_policy" {
  sink_identifier = aws_oam_sink.monitoring_account_oam_sink.id

 policy = jsonencode({
   Version = "2012-10-17"
   Statement = [
     {
       Action   = ["oam:CreateLink", "oam:UpdateLink"]
       Effect   = "Allow"
       Resource = "*"
       Principal = {
         "AWS" = var.source_account_ids
       }
       Condition = {
         "ForAllValues:StringEquals" = {
           "oam:ResourceTypes" = ["AWS::CloudWatch::Metric"]
         }
       }
     }
   ]
 })
}
