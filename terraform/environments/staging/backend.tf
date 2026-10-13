terraform {
  backend "s3" {
    bucket         = "awsevt-tf-state-10e6148a"
    key            = "staging/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "awsevt-tf-lock"
    encrypt        = true
  }
}
