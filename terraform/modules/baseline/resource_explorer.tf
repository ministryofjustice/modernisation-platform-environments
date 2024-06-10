resource "aws_resourceexplorer2_index" "this" {
  count = var.options.enable_resource_explorer == true ? 1 : 0
  type  = "LOCAL"
}

resource "aws_resourceexplorer2_view" "all_resources" {
  count        = var.options.enable_resource_explorer == true ? 1 : 0
  name         = "all-resources"
  default_view = true
  depends_on   = [aws_resourceexplorer2_index.this]
}
