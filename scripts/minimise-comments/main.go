package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"strings"
)

// JSON reponse structure from GraphQL query
type graphqlQuery struct {
	Data graphqlQueryData `json:"data"`
}

type graphqlQueryData struct {
	Repo graphqlQueryRepo `json:"repository"`
}

type graphqlQueryRepo struct {
	Pr graphqlQueryPr `json:"pullRequest"`
}

type graphqlQueryPr struct {
	Comments graphqlQueryComments `json:"comments"`
}

type graphqlQueryComments struct {
	Node []graphqlQueryNode `json:"nodes"`
}

type graphqlQueryNode struct {
	Id        string `json:"id"`
	Body      string `json:"body"`
	Minimized bool   `json:"isMinimized"`
}

var githubPr string = os.Getenv("PR_NUMBER")

func main() {
	if githubPr == "" {
		fmt.Println("Environment variable PR_NUMBER is an empty string.")
	} else {
		queryResult := postHttp(createQuery())
		queryUnmarshalled := unmarshalQuery(queryResult)
		idsToMinimise := commentIdsToMinimise(queryUnmarshalled)
		minimiseComments(idsToMinimise)
	}
}

// Assemble GraphQL query
func createQuery() []byte {
	githubOwnerRepo := os.Getenv("GITHUB_REPOSITORY")
	githubOwnerRepoList := strings.Split(githubOwnerRepo, "/")
	githubOwner := githubOwnerRepoList[0]
	githubRepo := githubOwnerRepoList[1]

	queryValue := fmt.Sprintf(`
		query {
			repository(owner: "%+v", name: "%+v") {
				pullRequest(number: %+v) {
					comments(last: 100, orderBy: { field: UPDATED_AT, direction: DESC }) {
						nodes {
							id
							body
							isMinimized
						}
					}
				}
			}
		}`, githubOwner, githubRepo, githubPr)

	queryData := map[string]string{
		"query": queryValue,
	}

	// Encode into JSON
	jsonValue, err := json.Marshal(queryData)
	if err != nil {
		panic(err)
	}

	return jsonValue
}

// Assemble GraphQL mutation
func createMutation(commentId string) []byte {
	mutationValue := fmt.Sprintf(`
		mutation {
			minimizeComment(input: {classifier: OUTDATED, subjectId: "%+v"}) {
				minimizedComment {
					minimizedReason
					isMinimized
				}
			}
	  	}`, commentId)

	mutationData := map[string]string{
		"query": mutationValue,
	}

	// Encode into JSON
	jsonValue, err := json.Marshal(mutationData)
	if err != nil {
		panic(err)
	}

	return jsonValue
}

func postHttp(postData []byte) []byte {
	// Get environment variables
	githubToken := os.Getenv("GITHUB_TOKEN")

	// HTTP request
	request, err := http.NewRequest("POST", "https://api.github.com/graphql", bytes.NewBuffer(postData))
	if err != nil {
		panic(err)
	}

	client := &http.Client{}

	// HTTP headers
	tokenHeader := "bearer " + githubToken
	request.Header.Add("content-type", "application/json")
	request.Header.Add("Authorization", tokenHeader)

	// HTTP response
	response, err := client.Do(request)
	if err != nil {
		panic(err)
	}

	defer response.Body.Close()

	// HTTP response data
	data, err := ioutil.ReadAll(response.Body)
	if err != nil {
		panic(err)
	}

	return data
}

func commentIdsToMinimise(response graphqlQuery) []string {

	numberOfComments := len(response.Data.Repo.Pr.Comments.Node)
	commentBodyContains := os.Getenv("COMMENT_BODY_CONTAINS")

	var idsToMinimize []string

	for i := 0; i < numberOfComments; i++ {
		if strings.Contains(response.Data.Repo.Pr.Comments.Node[i].Body, commentBodyContains) {
			idsToMinimize = append(idsToMinimize, response.Data.Repo.Pr.Comments.Node[i].Id)
		}
	}

	return idsToMinimize
}

func unmarshalQuery(results []byte) graphqlQuery {

	var response graphqlQuery

	err := json.Unmarshal(results, &response)
	if err != nil {
		fmt.Println(err)
	}

	return response
}

func minimiseComments(commentIds []string) {
	numberOfIds := len(commentIds)

	for i := 0; i < numberOfIds; i++ {
		responseBytes := postHttp(createMutation(commentIds[i]))
		responseString := string(responseBytes)
		fmt.Println("HTTP repsonse for comment ID", commentIds[i], ":", responseString)
	}
}