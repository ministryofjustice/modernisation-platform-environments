data "archive_file" "dummy" {
  type        = "zip"
  output_path = "${path.module}/dummy.zip"

  source {
    content  = "exports.handler = async (event) => { return { statusCode: 200, body: 'dummy' }; };"
    filename = "authorizer.js"
  }
}
