import yaml

class PromptService:
    def __init__(self):
        self.prompt = ""
    
    def parse_model_schema_from_yml(self, model):
        schema_file_path = f"./schemas/{model}.yml"

        with open(schema_file_path, "r", encoding="utf-8") as f:
            data = yaml.safe_load(f)

        return yaml.safe_dump(
            data,
            sort_keys=False,
            indent=2,
            default_flow_style=False,
            allow_unicode=True,
        )


    def create_new_prompt_section(self, title, content):
        return "\n\n\n" + title + "\n\n" + content

    def add_main_task(self):
        main_task = '''Given the user question, and the table schema below, 
generate a SQL statement, which will be run against the Athena table, to answer the question.'''

        section_title = "Task:"

        self.prompt += self.create_new_prompt_section(section_title, main_task)


    def add_model_schema(self, model):
        model_schema = self.parse_model_schema_from_yml(model)

        section_title = f"This is the schema of the {model} table:"

        self.prompt += self.create_new_prompt_section(section_title, model_schema)


    def add_user_question(self, question):
        section_title = "This is the question asked by the user:"

        self.prompt += self.create_new_prompt_section(section_title, question)


    def add_rule(self, rules, rule):
        rules.append(rule)


    def add_rules(self):
        section_title = "Rules:"

        rules = []

        self.add_rule(rules, "- Only respond with the generated SQL statement.")
        self.add_rule(rules, "- If the question is not relevant to the data model, respond with 'Please ask a relevant question.'.")
        self.add_rule(rules, "- Fuzzy match separators in string values.")
        self.add_rule(rules, "- Cloud Platform is the name of a team in the organisation.")

        self.prompt += self.create_new_prompt_section(section_title, "\n".join(rules))


    def build_prompt(self, model, question):
        print("Building prompt.")

        self.add_main_task()

        self.add_user_question(question)

        self.add_model_schema(model)

        self.add_rules()

        print(self.prompt)

        return self.prompt

