from services.llm_service import LLMService
from services.secret_service import SecretService
from services.athena_service import AthenaService


def lambda_handler(event, context): 
    print("Executing Lambda Handler")
    
    secret_service = SecretService()
    athena_service = AthenaService("cur_v2_database")

    api_key = secret_service.get_secret("llm_gateway_key")

    llm_service = LLMService(api_key)

    llm_service.test_llm_service()

    athena_service.test_athena_service()


if __name__ == "__main__":
    lambda_handler("", "")