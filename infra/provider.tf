terraform {
    required_version = ">=1.9" #terraform minimum version
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "5.74.0" #Specified aws-provider
        }
    }
    #add target bucket for tfstate. 
    backend "s3" {
        bucket = "pgr301-2024-terraform-state"
        key = "24/24-state.tfstate"
        region = "eu-west-1"
    }
}

provider "aws" {
    region = "eu-west-1"
}
