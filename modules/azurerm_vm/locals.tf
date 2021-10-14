locals {
  disk_map = {
    for i in range(var.data_disk_count) : i => {
      name = format("%s-disk%02d", var.name, (i + 1))
    }
  }
}