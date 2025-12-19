from services.bedrock_service import BedrockService

def lambda_handler(event, context): 
    bedrock_service = BedrockService()

    prompt = "Please respond to this request with 'Hello this is Bedrock'."

    response = bedrock_service.request_model_response_from_bedrock(prompt, "claude")

    print(response)