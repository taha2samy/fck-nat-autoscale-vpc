
variable "region" {
  default = "eu-west-1"
  type    = string
}
provider "aws" {
  region = var.region

}
data "aws_availability_zones" "azs" {
  state = "available"


}
