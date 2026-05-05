terraform {
  backend "s3" {
    bucket         = "victor-deliverer-bucket"
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-1"
    use_lockfile = true #this is another option for dynamodb_table = "terraform-state-locks"
    # dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}