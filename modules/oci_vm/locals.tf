locals {
  is_flex_shape = substr(var.instance_shape, -5, -1) == ".Flex" ? [var.default_flex_shape_ocpus]:[]
}
