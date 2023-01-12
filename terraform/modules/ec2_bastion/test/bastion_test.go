package main

import (
	"regexp"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestBastionCreation(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "./unit-test",
	})

	// Would fail if lifecycle.prevent_destroy is set on the bucket
	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)
	workspace := terraform.RunTerraformCommand(t, terraformOptions, "workspace", "show")

	bastionSecurityGroup := terraform.Output(t, terraformOptions, "bastion_security_group")
	bastionLaunchTemplate := terraform.Output(t, terraformOptions, "bastion_launch_template")
	bastionS3Bucket := terraform.Output(t, terraformOptions, "bastion_s3_bucket")

	assert.Regexp(t, regexp.MustCompile(`^sg-*`), bastionSecurityGroup)
	assert.Contains(t, bastionLaunchTemplate, "arn:aws:ec2:eu-west-2:")
	assert.Contains(t, bastionLaunchTemplate, "instance_type:t3.micro")
	assert.Contains(t, bastionS3Bucket, "arn:aws:s3:::bastion-"+workspace+"-")
}
