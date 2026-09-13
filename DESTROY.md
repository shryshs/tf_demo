# Teardown Guide — read this before running any `terraform destroy`

**Golden rule: destroy `envs/root` FIRST, `bootstrap` LAST — never the other
way round.** `bootstrap` holds the S3 bucket + state file that `envs/root`'s
state lives in. If you destroy `bootstrap` first, you lose the record of
what's actually running, and you're left hunting down a live VPC/ALB/ASG by
hand in the AWS console.

---

## Step 1 — Destroy the root environment (VPC, ALB, ASGs, IAM, everything)

```bash
cd envs/root
terraform destroy
```

Type `yes` when prompted (or add `-auto-approve` to skip the prompt).

This is a single command — it tears down **both** blue and green together
(they're both in the same state), and Terraform works out the correct order
on its own:

```
ALB listener  →  target groups  →  ASGs  →  launch templates
IAM role policy attachment  →  IAM instance profile  →  IAM role
EC2 security group  →  ALB security group
subnets + route table associations  →  route table  →  internet gateway  →  VPC
```

You don't need to delete anything individually or in a special order
yourself — that's the whole point of using Terraform.

---

## Step 2 — Confirm nothing real is left behind

```bash
terraform state list
```

Should print nothing (empty state = nothing left for Terraform to track).

Optional sanity check directly against AWS, in case something got stuck:

```bash
aws elbv2 describe-load-balancers --region ap-south-1
aws ec2 describe-instances --region ap-south-1 --filters "Name=instance-state-name,Values=running"
```

Both should come back empty for anything related to this project.

---

## Step 3 — Empty the remote-state S3 bucket

The bucket has **versioning enabled**, so Terraform (or even the AWS console)
can't delete it while any object version or delete marker still exists
inside it — you have to empty it first.

```bash
BUCKET="tfstate-backend-shr-bucket"   # the one from bootstrap's output

# Delete every object version
aws s3api delete-objects --bucket "$BUCKET" --delete "$(
  aws s3api list-object-versions --bucket "$BUCKET" \
    --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' \
    --output json
)"

# Delete every delete-marker (versioning creates these instead of a real delete)
aws s3api delete-objects --bucket "$BUCKET" --delete "$(
  aws s3api list-object-versions --bucket "$BUCKET" \
    --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' \
    --output json
)"
```

Run `aws s3 ls s3://$BUCKET --recursive` afterwards — it should print nothing.

> **Shortcut for next time:** add `force_destroy = true` to the
> `aws_s3_bucket "state"` resource in `bootstrap/main.tf` *before* you ever
> apply it. Then `terraform destroy` in Step 4 empties and deletes the
> bucket automatically, and you can skip this whole step. It only works if
> it's set before you no longer need the bucket — can't retro-apply it once
> you're mid-teardown with no compute left to run `terraform apply` against
> (though in practice you can still `terraform apply` bootstrap alone to add
> this flag, since bootstrap keeps its own separate local state).

---

## Step 4 — Destroy bootstrap (S3 bucket + DynamoDB lock table)

Only after Steps 1–3 are done:

```bash
cd ../../bootstrap
terraform destroy
```

Type `yes` when prompted. This removes the state bucket and the DynamoDB
lock table — the very last things standing.

---

## Full sequence, copy-paste version

```bash
# 1) destroy everything root manages
cd envs/root
terraform destroy

# 2) sanity check
terraform state list

# 3) empty the state bucket (skip if you set force_destroy = true earlier)
BUCKET="your-tf-state-bucket-name"
aws s3api delete-objects --bucket "$BUCKET" --delete "$(aws s3api list-object-versions --bucket "$BUCKET" --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --output json)"
aws s3api delete-objects --bucket "$BUCKET" --delete "$(aws s3api list-object-versions --bucket "$BUCKET" --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' --output json)"

# 4) destroy the backend itself
cd ../../bootstrap
terraform destroy
```
