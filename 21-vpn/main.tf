resource "aws_instance" "openvpn" {
    ami = local.ami_id
    instance_type = "t3.micro"
    vpc_security_group_ids = [local.open_vpn_sg_id]
    subnet_id = local.public_subnet_id
    user_data = file("vpn.sh")
    
    tags = merge (
        local.common_tags,
        {
            Name = "${var.project_name}-${var.environment}-vpn"
        }
    )
}

resource "aws_route53_record" "openvpn" {
  zone_id = var.zone_id
  name    = "openvpn.${var.domain_name}" # openvpn-dev.0gworld.shop
  type    = "A"
  ttl     = 1
  records = [aws_instance.openvpn.public_ip]
  allow_overwrite = true
}

