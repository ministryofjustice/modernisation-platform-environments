import json
from openai import OpenAI

class LLMService:
    def __init__(self, api_key) -> None:
        self.client = OpenAI(
            base_url="https://llm-gateway.development.data-platform.service.justice.gov.uk",
            api_key=api_key
        )


    def clean_sql_response(self, response):
        if response.startswith("```sql") and response.endswith("```"):
            return response[len("```sql"): -len("```")].strip()


    def request_model_response(self, prompt):
        print("Requesting model response.")
        
        response = self.client.chat.completions.create(
            model="bedrock-claude-sonnet-4-5",
            messages = [
                {
                    "role": "user",
                    "content": prompt
                }
            ]
        )

        result = response.model_dump_json(indent=3)

        result_json = json.loads(result)

        message_content = result_json.get('choices', [])[0].get('message', {}).get('content', "")

        sql_statement = self.clean_sql_response(message_content)

        print("Generated query:")
        print(sql_statement)

        return sql_statement
    

    def test_llm_service(self):
        prompt = "Please respond to this request with 'Hello this is Claude'.."

        llm_response = self.request_model_response(prompt)

        print(f"Test LLM Service: {llm_response}")
