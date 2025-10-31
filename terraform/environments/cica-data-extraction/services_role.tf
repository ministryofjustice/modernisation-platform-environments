resource "aws_iam_policy" "cica_extraction_policy" {
  name        = "AuthenticatedCicaExtractionPolicy"
  description = "Policy for Cica Bedrock model access and Textract"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AuthenticatedCicaExtractionPolicy",
        Effect = "Allow",
        Action = [
          "bedrock:InvokeModel",
          "bedrock:Get*",
          "bedrock:List*"
        ],
        Resource = [
          "arn:aws:bedrock:eu-central-1::foundation-model/amazon.titan-embed-text-v1",
          "arn:aws:bedrock:eu-central-1::foundation-model/anthropic.claude-v2",
          "arn:aws:bedrock:eu-central-1::foundation-model/anthropic.claude-v2:1",
          "arn:aws:bedrock:eu-central-1::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0",
          "arn:aws:bedrock:eu-central-1::foundation-model/anthropic.claude-3-5-sonnet-20240620-v1:0",
          "arn:aws:bedrock:eu-central-1::foundation-model/anthropic.claude-3-haiku-20240307-v1:0"
        ]
      },
      {
        Sid    = "TextractPolicy",
        Effect = "Allow",
        Action = [
          "textract:AnalyzeDocument",
          "textract:GetDocumentAnalysis",
          "textract:GetDocumentTextDetection",
          "textract:StartDocumentTextDetection",
          "textract:StartDocumentAnalysis",
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "cica_extraction_role" {
  name = "CicaExtractionServicesRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cica_extraction_policy_attachment" {
  role       = aws_iam_role.cica_extraction_role.name
  policy_arn = aws_iam_policy.cica_extraction_policy.arn
}
