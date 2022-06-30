package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"strings"
	"testing"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials/stscreds"
	"github.com/aws/aws-sdk-go-v2/service/iam"
	"github.com/aws/aws-sdk-go-v2/service/secretsmanager"
	"github.com/aws/aws-sdk-go-v2/service/sts"
	"github.com/stretchr/testify/assert"
	"golang.org/x/exp/slices"
)

/**
CLI examples:
aws secretsmanager get-secret-value --secret-id environment_management --profile mod --region eu-west-2
aws secretsmanager get-secret-value --secret-id nuke_account_ids --profile mod --region eu-west-2 --query 'SecretString' --output text --no-cli-pager
*/
func getSecret(cfg aws.Config, secretName string) string {
	client := secretsmanager.NewFromConfig(cfg)
	input := &secretsmanager.GetSecretValueInput{
		SecretId:     aws.String(secretName),
		VersionStage: aws.String("AWSCURRENT"),
	}
	result, err := client.GetSecretValue(context.TODO(), input)
	if err != nil {
		log.Println(err.Error())
	}
	return *result.SecretString
}

func getNonProdAccounts(cfg aws.Config) map[string]string {
	accounts := make(map[string]string)
	// Get accounts secret
	environments := getSecret(cfg, "environment_management")

	var allAccounts map[string]interface{}
	json.Unmarshal([]byte(environments), &allAccounts)

	for _, record := range allAccounts {
		if rec, ok := record.(map[string]interface{}); ok {
			for key, val := range rec {
				// Skip if the account has "prod" in it's name, for example: production, pre-production will be skipped
				if !strings.Contains(key, "prod") {
					accounts[key] = val.(string)
				}
			}
		}
	}
	return accounts
}

func getAutoNukedAccountIds(cfg aws.Config) []string {
	var accountIds []string
	secret := getSecret(cfg, "nuke_account_ids")

	var accounts map[string]interface{}
	json.Unmarshal([]byte(secret), &accounts)

	for _, record := range accounts {
		if rec, ok := record.(map[string]interface{}); ok {
			for _, val := range rec {
				accountIds = append(accountIds, val.(string))
			}
		}
	}
	return accountIds
}

/**
Check whether the given account has a sandbox role associated to it.
From command line, you would use `aws iam list-roles`.
*/
func isSandboxAccount(cfg aws.Config, accountId string) bool {
	roleARN := fmt.Sprintf("arn:aws:iam::%v:role/ModernisationPlatformAccess", accountId)
	stsClient := sts.NewFromConfig(cfg)
	provider := stscreds.NewAssumeRoleProvider(stsClient, roleARN)
	cfg.Credentials = aws.NewCredentialsCache(provider)

	client := iam.NewFromConfig(cfg)
	outRoles, err := client.ListRoles(context.TODO(), &iam.ListRolesInput{
		PathPrefix: aws.String("/")})

	if err != nil {
		fmt.Println("Error", err)
		return false
	}

	// For simplicity and less dereferencing: more execution speed
	rolesList := outRoles.Roles

	for i := range rolesList {
		roleName := *rolesList[i].RoleName
		if strings.Contains(roleName, "sandbox") {
			return true
		}
	}
	return false
}

func getSandboxAccounts(cfg aws.Config) map[string]string {
	accounts := make(map[string]string)
	nonProdAccounts := getNonProdAccounts(cfg)
	for accName, accId := range nonProdAccounts {
		if isSandboxAccount(cfg, accId) {
			accounts[accName] = accId
		}
	}
	return accounts
}

func TestSandboxAccountsAreAutoNuked(t *testing.T) {
	t.Parallel()

	// Load the Shared AWS Configuration (~/.aws/config)
	cfg, err := config.LoadDefaultConfig(context.TODO())
	if err != nil {
		log.Fatal(err)
	}

	autoNukedAccountIds := getAutoNukedAccountIds(cfg)
	sandboxAccounts := getSandboxAccounts(cfg)
	sandboxNonAutoNukedAccounts := make(map[string]string)
	for accName, accId := range sandboxAccounts {
		if !slices.Contains(autoNukedAccountIds, accId) {
			sandboxNonAutoNukedAccounts[accName] = accId
		}
	}
	assert.Empty(t, sandboxNonAutoNukedAccounts, "Sandbox accounts were found that need to be added to the auto-nuke list (nuke_account_ids secret): https://user-guide.modernisation-platform.service.justice.gov.uk/concepts/environments/auto-nuke.html")
}
