from services.llm_service import LLMService
from services.secret_service import SecretService
from services.athena_service import AthenaService
from services.prompt_service import PromptService
from lib.response import construct_error, construct_response
from lib.validators import validate_user_question


def lambda_handler(event, context): 
    print("Request Payload:")
    print(event)
    
    print("Executing Lambda Handler.")
    
    secret_service = SecretService()
    athena_service = AthenaService("cur_v2_database")
    prompt_service = PromptService()

    user_question = validate_user_question(event.get("user_question", "No question was submitted"))
    model = "fct_daily_cost"

    api_key = secret_service.get_secret("llm_gateway_key")

    llm_service = LLMService(api_key)

    prompt = prompt_service.build_prompt(model, user_question)

    try:
        query = llm_service.request_model_response(prompt)

        query_result= athena_service.run_query(query)
    except Exception as err:
        return construct_error(err)

    response = construct_response(query, query_result)

    return response


if __name__ == "__main__":
    response = lambda_handler({"user_question": '''
How much did HMPPS spend last month?
'''}, "")
    
    print(response)