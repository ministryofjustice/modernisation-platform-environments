data "http" "github_meta" {
  request_headers = {
    Accept = "application/json"
  }
  url = "https://api.github.com/meta"
}
