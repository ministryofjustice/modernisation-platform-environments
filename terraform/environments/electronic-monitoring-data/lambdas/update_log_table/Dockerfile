FROM public.ecr.aws/lambda/python:3.11

COPY requirements.txt .

RUN pip install -r requirements.txt --target "${LAMBDA_TASK_ROOT}"

COPY update_log_table.py ${LAMBDA_TASK_ROOT}

CMD ["update_log_table.handler"]
