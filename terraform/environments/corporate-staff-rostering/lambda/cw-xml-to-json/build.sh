#!/usr/bin/env bash

readonly SERVER_URL=111122223333.dkr.ecr.us-east-1.amazonaws.com
readonly REPO_NAME=hello-world

tag=$1

docker build \
	--platform linux/amd64 \
	-t "docker-image:$tag" \
	.

aws ecr get-login-password \
	--region us-east-1 |
	docker login \
		--username AWS \
		--password-stdin $SERVER_URL

docker tag "$REPO_NAME:$tag" "$SERVER_URL/$REPO_NAME:$tag"

docker push "$SERVER_URL/$REPO_NAME:$tag"
