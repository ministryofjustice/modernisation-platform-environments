import boto3, json
from config import CLAUDE_MODEL_ID, LLAMA_MODEL_ID


class BedrockService:
    def __init__(self) -> None:
        self.client = boto3.client("bedrock", region_name="eu-west-2")

    def request_model_response_from_bedrock(self, prompt, model):

        bedrock_runtime = boto3.client(
            service_name="bedrock-runtime",
            region_name="eu-west-2",
        )

        model_id = ""
        model_request = {}

        if model == "llama":
            model_request = self.format_llama_request(prompt)
            model_id = LLAMA_MODEL_ID

            response = bedrock_runtime.invoke_model(
                modelId=model_id,
                body=json.dumps(model_request),
            )

            response_body = json.loads(response["body"].read())
            result = response_body["generation"]

        else:
            model_request = self.format_claude_request(prompt)
            model_id = CLAUDE_MODEL_ID

            response = bedrock_runtime.invoke_model(
                modelId=model_id,
                body=json.dumps(model_request),
            )

            result = json.loads(response.get("body").read()).get("content", [])[0].get("text", "")

        return result

    def format_claude_request(self, prompt):
        model_kwargs = {
            "max_tokens": 4096,
            "temperature": 0.1,
            "top_k": 250,
            "top_p": 1
        }

        request = {
            "anthropic_version": "bedrock-2023-05-31",
            "messages": [
                {"role": "user", "content": [{"type": "text", "text": prompt}]},
            ],
        }

        request.update(model_kwargs)

        return request

    def format_llama_request(self, prompt):
        request = {
            "prompt": prompt,
            "temperature": 0.5,
            "top_p": 0.9,
            "max_gen_len": 2048,
        }
        
        return request