APP_NAME = update_log_table
APP_VERSION := $(shell terraform -chdir=../../ output -raw account_suffix)

.PHONY: print-account-suffix
print-account-suffix:
	@echo APP_VERSION=$(APP_VERSION)

AWS_ECR_ACCOUNT_ID := $(shell terraform -chdir=../../ output -raw account_id)

.PHONY: print-account-id
print-account-id:
	@echo AWS_ECR_ACCOUNT_ID=$(AWS_ECR_ACCOUNT_ID)


AWS_ECR_REGION = eu-west-2
AWS_ECR_REPO = lambdas/$(APP_NAME)

TAG = $(APP_VERSION)

.PHONY: docker/build docker/push docker/run docker/test

docker/build :
	docker build -t $(APP_NAME):$(APP_VERSION) .

docker/push: docker/build
	aws ecr get-login-password --region $(AWS_ECR_REGION) | docker login --username AWS --password-stdin $(AWS_ECR_ACCOUNT_ID).dkr.ecr.$(AWS_ECR_REGION).amazonaws.com
	docker tag $(APP_NAME):$(APP_VERSION) $(AWS_ECR_ACCOUNT_ID).dkr.ecr.$(AWS_ECR_REGION).amazonaws.com/$(AWS_ECR_REPO):$(TAG)
	docker push $(AWS_ECR_ACCOUNT_ID).dkr.ecr.$(AWS_ECR_REGION).amazonaws.com/$(AWS_ECR_REPO):$(TAG)

docker/run:
	docker run -p 9000:8080 $(AWS_ECR_ACCOUNT_ID).dkr.ecr.$(AWS_ECR_REGION).amazonaws.com/$(AWS_ECR_REPO):$(TAG)

docker/test:
	curl -XPOST 'http://localhost:9000/2015-03-31/functions/function/invocations' -d '{"input": {"test/*/Financials": "s3://dms-rds-to-parquet-20240606142913727200000001/test/dbo/Financials/LOAD00000001.parquet","db_info": ["test","dbo","Financials"]},"inputDetails": {"truncated": false},"resource": "arn:aws:lambda:eu-west-2:800964199911:function:update_log_table"}'
