package test

import (
	"fmt"
	"io"
	"log"
	"net/http"
	testing "testing"
	"time"

	terra_test "github.com/gruntwork-io/terratest/modules/testing"
	"github.com/stretchr/testify/assert"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestApiGateway(t *testing.T) {
	uniqueId := random.UniqueId()
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "test_terraform",
		Vars: map[string]interface{}{
			"environment": fmt.Sprintf("terratest-%s", uniqueId),
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)
	time.Sleep(30 * time.Second)

	gatewayId := terraform.Output(t, terraformOptions, "gateway_id")
	stageUrl := fmt.Sprintf("https://%s.execute-api.eu-west-2.amazonaws.com/test/", gatewayId)

	statusCode := DoGetRequest(t, stageUrl, "placeholder")
	assert.Equal(t, 200, statusCode)

	statusCode = DoGetRequest(t, stageUrl, "wrong")
	assert.Equal(t, 403, statusCode)
}

func DoGetRequest(t terra_test.TestingT, api string, token string) int {
	client := &http.Client{}

	log.Println(api)

	req, err := http.NewRequest("GET", api, nil)
	if err != nil {
		log.Fatalln(err)
	}

	req.Header.Add("authorizationToken", token)

	resp, err := client.Do(req)
	if err != nil {
		log.Fatalln(err)
	}

	if resp.StatusCode != 200 {
		// Print all response headers for debugging
		for name, values := range resp.Header {
			for _, value := range values {
				log.Println(name, value)
			}
		}

		// Print response body for debugging
		b, _ := io.ReadAll(resp.Body)
		log.Println("body " + string(b))

	}

	return resp.StatusCode
}
