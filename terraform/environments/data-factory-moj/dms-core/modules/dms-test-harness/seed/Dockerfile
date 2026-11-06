# checkov:skip=CKV_DOCKER_2:AWS Lambda manages container health; Docker HEALTHCHECK is not used by the Lambda execution model.
# checkov:skip=CKV_DOCKER_3:AWS Lambda runs functions using its managed least-privileged runtime user.

FROM public.ecr.aws/lambda/python:3.12-arm64

COPY requirements.txt ${LAMBDA_TASK_ROOT}/

RUN pip install \
    --no-cache-dir \
    -r ${LAMBDA_TASK_ROOT}/requirements.txt \
    --target ${LAMBDA_TASK_ROOT}

COPY lambda_function.py ${LAMBDA_TASK_ROOT}/

CMD ["lambda_function.lambda_handler"]
