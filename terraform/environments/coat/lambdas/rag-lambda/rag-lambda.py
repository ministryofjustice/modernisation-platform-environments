import json
from services.llm_service import LLMService
from services.secret_service import SecretService
from services.athena_service import AthenaService
from services.prompt_service import PromptService


def construct_response(query, data):
    return json.dumps(
        {
            "query": query,
            "data": data
        }
    )


def lambda_handler(event, context): 
    print("Executing Lambda Handler.")
    
    secret_service = SecretService()
    athena_service = AthenaService("cur_v2_database")
    prompt_service = PromptService()

    user_question = event.get("user_question", "No question was submitted")
    model = "fct_daily_cost"

    api_key = secret_service.get_secret("llm_gateway_key")

    llm_service = LLMService(api_key)

    prompt = prompt_service.build_prompt(model, user_question)

    query = llm_service.request_model_response(prompt)
    
    query_result= athena_service.run_query(query)

    response = construct_response(query, query_result)

    return response


if __name__ == "__main__":
    response = lambda_handler({"user_question": '''
What was the cost of the uga-duba account for each day in the last month?
'''}, "")
    
    print(response)