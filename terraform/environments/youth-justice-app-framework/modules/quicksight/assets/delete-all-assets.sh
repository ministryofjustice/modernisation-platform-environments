#!/bin/sh

#Set variables
aws_account_id=$1

aws quicksight delete-dashboard --aws-account-id ${aws_account_id} --dashboard-id 89ded068-ff94-4391-984a-8bc8bb0ec7d5

aws quicksight delete-template --aws-account-id ${aws_account_id} --template-id Disparity_Toolkit_v1_2

aws quicksight delete-analysis --aws-account-id ${aws_account_id} --analysis-id 4847a16c-19d4-4544-9631-e867127724e1

aws quicksight delete-data-set --aws-account-id ${aws_account_id} --data-set-id d8ea9805-4eff-40c6-b6f5-8e11f566a7a0
aws quicksight delete-data-set --aws-account-id ${aws_account_id} --data-set-id b2717907-0301-4daa-b777-5f662a2ebd40
aws quicksight delete-data-set --aws-account-id ${aws_account_id} --data-set-id 03b1c5a2-fe9a-4219-b8cc-9b248cefd324
aws quicksight delete-data-set --aws-account-id ${aws_account_id} --data-set-id 7d6329ad-b523-4c4e-ad6b-86d8b1a06f81



