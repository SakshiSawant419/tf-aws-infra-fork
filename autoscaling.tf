resource "aws_autoscaling_group" "webapp_asg" {
  name                      = "webapp-asg"
  desired_capacity          = 3
  max_size                  = 5
  min_size                  = 3
  vpc_zone_identifier       = local.selected_public_subnets
  target_group_arns         = [aws_lb_target_group.webapp_tg.arn]

  health_check_type         = "ELB" # ✅ This is CRUCIAL
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.webapp_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "webapp-instance"
    propagate_at_launch = true
  }
}

# Auto Scaling Policies
resource "aws_autoscaling_policy" "scale_up" {
  name                    = "cpu-scale-up"
  autoscaling_group_name  = aws_autoscaling_group.webapp_asg.name
  adjustment_type         = "ChangeInCapacity"
  scaling_adjustment      = 1
  cooldown                = 60
  policy_type             = "SimpleScaling"
  metric_aggregation_type = "Average"
}

resource "aws_autoscaling_policy" "scale_down" {
  name                    = "cpu-scale-down"
  autoscaling_group_name  = aws_autoscaling_group.webapp_asg.name
  adjustment_type         = "ChangeInCapacity"
  scaling_adjustment      = -1
  cooldown                = 60
  policy_type             = "SimpleScaling"
  metric_aggregation_type = "Average"
}

# CloudWatch Alarms for Auto Scaling

# Scale-Up Alarm (CPU > 5%)
resource "aws_cloudwatch_metric_alarm" "high_cpu_alarm" {
  alarm_name          = "High-CPU-Alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 5

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.webapp_asg.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_up.arn]
}

# Scale-Down Alarm (CPU < 10%)
resource "aws_cloudwatch_metric_alarm" "low_cpu_alarm" {
  alarm_name          = "Low-CPU-Alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1 # Faster reaction
  period              = 60
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  statistic           = "Average"
  threshold           = 3 # Easier to trigger

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.webapp_asg.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_down.arn]
}