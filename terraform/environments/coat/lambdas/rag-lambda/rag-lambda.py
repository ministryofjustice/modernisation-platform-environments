from services.llm_service import LLMService
from services.secret_service import SecretService

def lambda_handler(event, context): 
    secret_service = SecretService()

    api_key = secret_service.get_secret("llm_gateway_key")

    llm_service = LLMService(api_key)

    prompt = "Please respond to this request with 'Hello this is Claude'.."

    response = llm_service.request_model_response(prompt)

    print(response)