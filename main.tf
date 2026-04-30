provider "aws" {
  region = "eu-west-1"
}

resource "aws_instance" "instance1" {
  ami           = "ami-0442403fb8d244144"
  instance_type = "t2.micro"

  tags = {
    Name = "30-days-terraform"
  }

}