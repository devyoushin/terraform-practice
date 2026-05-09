resource "aws_ram_resource_share" "this" {
  name                      = var.name
  allow_external_principals = var.allow_external_principals

  tags = merge(var.tags, { Name = var.name })
}

resource "aws_ram_resource_association" "tgw" {
  resource_arn       = var.transit_gateway_arn
  resource_share_arn = aws_ram_resource_share.this.arn
}

resource "aws_ram_principal_association" "this" {
  for_each = toset(var.principals)

  principal          = each.value
  resource_share_arn = aws_ram_resource_share.this.arn
}
