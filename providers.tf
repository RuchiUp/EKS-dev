terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.3.0"
}

provider "aws" {
  region     = "us-west-2"
  access_key = ""
  secret_key = ""
  profile    = "Ruchi_demo"

}