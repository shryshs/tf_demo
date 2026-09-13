terraform {
  backend "s3" {
    bucket         = "tfstate-backend-shr-bucket"
    key            = "blue-green/root/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
