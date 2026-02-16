resource "aws_lightsail_instance" "draft_chamber" {
  name              = "draft-chamber"
  availability_zone = "ap-northeast-1d"
  blueprint_id      = "ubuntu_24_04"
  bundle_id         = "micro_ipv6_3_0" # 512MB RAM, 2 vCPU, 20GB SSD, and 1TB transfer
  ip_address_type   = "ipv6"
  key_pair_name     = "draft-chamber-lightsail"
  add_on {
    type          = "AutoSnapshot"
    snapshot_time = "00:00"
    status        = "Enabled"
  }
}

resource "aws_lightsail_instance_public_ports" "draft_chamber" {
  instance_name = aws_lightsail_instance.draft_chamber.name
  port_info {
    protocol  = "tcp"
    from_port = 80
    to_port   = 80
  }
  port_info {
    protocol  = "tcp"
    from_port = 443
    to_port   = 443
  }
  port_info {
    protocol  = "tcp"
    from_port = 9922
    to_port   = 9922
  }
}
