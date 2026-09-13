# launch-template.tf

resource "aws_launch_template" "app" {
  name = "myapp-launch-template"

  image_id = var.ami_id

  instance_type = "t3.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  vpc_security_group_ids = [
    aws_security_group.ec2.id
  ]

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash

    set -eux

    # Update package information
    apt-get update -y

    # Install nginx
    apt-get install -y nginx

    # Enable nginx at boot
    systemctl enable nginx

    # Start nginx
    systemctl start nginx

    # Simple test page
    cat > /var/www/html/index.html <<HTML
    <!DOCTYPE html>
    <html>
    <head>
        <title>My Application</title>
    </head>
    <body>
        <h1>Hello from Nginx!</h1>
        <p>Hostname: $(hostname)</p>
        <p>Environment: dev</p>
    </body>
    </html>
    HTML
  EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "myapp-server"
      Environment = "dev"
      Terraform   = "true"
    }
  }
}
