# `terraform destroy` steps:

**Note: destroy `envs/root` FIRST, `bootstrap` LAST — never the other
way round.** `bootstrap` holds the S3 bucket + state file that `envs/root`'s
state lives in. If you destroy `bootstrap` first, you lose the record of
what's actually running, and you're left hunting down a live VPC/ALB/ASG by
hand in the AWS console.

---

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
