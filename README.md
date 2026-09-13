# Terraform Blue-Green Web Environment — Commands

## PART 1 — Build Alpha

```bash
# 1) Create the remote-state backend (ONCE, ever)
cd bootstrap
terraform init
terraform apply -var="state_bucket_name=tfstate-backend-shr-bucket" -var="region=ap-south-1"
# note the outputs: state_bucket_name, lock_table_name

# 2) Put that bucket name into envs/root/backend.tf (replace CHANGE-ME)

# 3) Put your Ubuntu AMI id into envs/root/terraform.tfvars (blue_ami_id)

# 4) Format, validate, plan, apply
cd ../envs/root
terraform fmt -recursive
terraform init
terraform validate
terraform plan
terraform apply

# 5) Test it
curl http://$(terraform output -raw alb_dns_name)/
```

## PART 2 — Blue-Green cutover to Beta

```bash
# Step 1: confirm 100% blue
curl http://$(terraform output -raw alb_dns_name)/     # -> alpha-v1.0

# Step 2: stand up green with ZERO traffic
# edit terraform.tfvars:
#   enable_green = true
#   green_ami_id = "ami-your-ubuntu-ami"
#   blue_weight  = 100
#   green_weight = 0
terraform plan
terraform apply

# Step 3: cutover — start the watcher first, then flip the weights
./../../scripts/cutover_test.sh $(terraform output -raw alb_dns_name) 90 0.2
# in a second terminal, edit terraform.tfvars:
#   blue_weight  = 0
#   green_weight = 100
terraform plan
terraform apply

# Step 4: rollback — same mechanism, reversed
# edit terraform.tfvars:
#   blue_weight  = 100
#   green_weight = 0
terraform plan
terraform apply
```

For canary testing:
```
cd envs/root
./../../scripts/canary_rollout.sh 30 0.2
```