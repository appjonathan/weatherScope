// AWS Provider Konfiguration
provider "aws" {
  region = "eu-central-1" // Region für die AWS-Ressourcen
  # access_key = ""
  # secret_key = ""
}

// Sicherheitsgruppe für die EC2-Instanz
resource "aws_security_group" "weatherapp-sg" {
  name        = "weatherapp-sg"
  description = "Security Group for the  main-instance"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// Launch-Konfiguration für EC2-Instanzen
resource "aws_launch_configuration" "weatherapp-main-instance" {
  name          = "weatherapp-main-instance"
  image_id      = "ami-04f9a173520f395dd"
  instance_type = "t2.small"
  key_name      = "myMasterkey" 
  security_groups = [aws_security_group.weatherapp-sg.id]

  // User data script
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y

              cd /home/ubuntu/

              curl -fsSL https://deb.nodesource.com/setup_21.x | sudo -E bash -
              sudo apt-get install -y nodejs
              sudo npm install -g npm@latest

              git clone https://github.com/appjonathan/weatherScope.git
              cd weatherScope
              touch .env.local
              echo "NEXT_PUBLIC_WEATHER_API_KEY = '3a621ee35fd8fd2a3e694094e66003a5'" >> .env.local
              npm install
              npm run dev
              EOF

  lifecycle {
    create_before_destroy = true // Erstellt eine neue Ressource, bevor die alte zerstört wird
  }
}

// Load Balancer
resource "aws_lb" "weatherapp-load-balancer" {
  name               = "weatherapp-load-balancer" 
  internal           = false // Bestimmt, ob der Load Balancer intern ist
  load_balancer_type = "application" // Typ des Load Balancers
  security_groups    = [aws_security_group.weatherapp-sg.id] // Sicherheitsgruppen für den Load Balancer
  subnets            = ["subnet-00e3b4011fa9ae70b", "subnet-07506b97a1c362329", "subnet-0a4fa22c17231755f"] // Subnetze für den Load Balancer
}

// Zielgruppe für den Load Balancer
resource "aws_lb_target_group" "weatherapp-target-group" {
  name     = "weatherapp-target-group"
  port     = 80 // Port für die Zielgruppe
  protocol = "HTTP" // Protokoll für die Zielgruppe
  vpc_id   = "vpc-05defb78bccd9d65e" // VPC-ID für die Zielgruppe
}

// Listener für den Load Balancer
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.weatherapp-load-balancer.arn // ARN des Load Balancers
  port              = "80" // Port für den Listener
  protocol          = "HTTP" // Protokoll für den Listener

  default_action {
    type             = "forward" // Typ der Standardaktion
    target_group_arn = aws_lb_target_group.weatherapp-target-group.arn // ARN der Zielgruppe für die Standardaktion
  }
}

// Auto Scaling Gruppe
resource "aws_autoscaling_group" "weatherapp-auto-scaling" {
  desired_capacity   = 1 // Gewünschte Kapazität der Auto Scaling Gruppe
  launch_configuration = aws_launch_configuration.weatherapp-main-instance.name // Verwendet die oben definierte Launch-Konfiguration
  max_size           = 3 // Maximale Größe der Auto Scaling Gruppe
  min_size           = 1 // Minimale Größe der Auto Scaling Gruppe
  vpc_zone_identifier  = ["subnet-00e3b4011fa9ae70b", "subnet-07506b97a1c362329", "subnet-0a4fa22c17231755f"] // Subnetz-IDs für die Auto Scaling Gruppe

  target_group_arns = [aws_lb_target_group.weatherapp-target-group.arn] // Zielgruppen für die Load Balancer

  lifecycle {
    create_before_destroy = true // Erstellt eine neue Ressource, bevor die alte zerstört wird
  }
}

// Skalierungsrichtlinie für die Auto Scaling Gruppe
resource "aws_autoscaling_policy" "weatherapp-scaleUp-policy" {
  name                   = "weatherapp-scaleUp-policy"
  autoscaling_group_name = aws_autoscaling_group.weatherapp-auto-scaling.name // Name der Auto Scaling Gruppe
  adjustment_type        = "ChangeInCapacity" // Anpassungstyp der Skalierungsrichtlinie
  scaling_adjustment     = 1 // Skalierungsanpassung der Skalierungsrichtlinie
  cooldown               = 300 // Abkühlzeit der Skalierungsrichtlinie
}

// CloudWatch-Alarm für hohe CPU-Auslastung
resource "aws_cloudwatch_metric_alarm" "weatherapp-cpu-high-alarm" {
  alarm_name          = "weatherapp-cpu-high-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold" // Vergleichsoperator für den Alarm
  evaluation_periods  = "2" // Auswertungsperioden für den Alarm
  metric_name         = "CPUUtilization" // Metrikname für den Alarm
  namespace           = "AWS/EC2" // Namespace für den Alarm
  period              = "120" // Periode für den Alarm
  statistic           = "Average" // Statistik für den Alarm
  threshold           = "80" // Schwellenwert für den Alarm
  alarm_description   = "This metric checks cpu utilization" // Beschreibung des Alarms
  alarm_actions       = [aws_autoscaling_policy.weatherapp-scaleUp-policy.arn] // Aktionen bei Auslösung des Alarms
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.weatherapp-auto-scaling.name // Dimensionen für den Alarm
  }
}