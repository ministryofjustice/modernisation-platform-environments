# How to run the tests

Run the tests from within the `go-tests` directory

```
aws-vault exec mod -- go test -v
```

Upon successful run, you should see an output similar to the below

```
--- PASS: TestSandboxAccountsAreAutoNuked (7.44s)
PASS
ok      github.com/ministryofjustice/modernisation-platform-environments        7.677s
```

## Module initialisation

The following commands were used in order to generate the required `go.mod` and `go.sum` files prior to the first run of the tests.

```
go mod init github.com/ministryofjustice/modernisation-platform-environments
go mod tidy
go mod download
```

## References

1. https://www.digitalocean.com/community/tutorials/how-to-write-unit-tests-in-go-using-go-test-and-the-testing-package
