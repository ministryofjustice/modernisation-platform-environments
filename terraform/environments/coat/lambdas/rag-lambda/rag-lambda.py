from services.llm_service import LLMService

def lambda_handler(event, context): 
    llm_service = LLMService()

    prompt = "Please respond to this request with 'Hello this is Claude'."

    response = llm_service.request_model_response(prompt)

    print(response)