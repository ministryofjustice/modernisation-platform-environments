resource "aws_iam_role" "dms_validation_event_bridge_invoke_sfn_role" {
    name = var.event_bridge_role_name
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow"
            Principal = { Service = "events.amazonaws.com"}
            Action  = "sts:AssumeRole"
        }]
        
    })
}

resource "aws_iam_role_policy" "event_bridge_invoke_sfn_policy" {
    role = aws_iam_role.dms_validation_event_bridge_invoke_sfn_role.arn
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow"
            Action  = [
                "states:StartExecution",
            ]
            Resource = var.dms_validation_step_function_arn
        }]
    }) 
}
