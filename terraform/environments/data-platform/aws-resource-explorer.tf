resource "aws_resourceexplorer2_index" "eu_west_2" {
  type = "LOCAL"

  tags = local.tags
}

resource "aws_resourceexplorer2_view" "eu_west_2" {
  name = "eu-west-2"

  tags = local.tags

  depends_on = [aws_resourceexplorer2_index.eu_west_2]
}
