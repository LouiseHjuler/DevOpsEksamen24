variable "region" {
  description = "The AWS region to deploy resources in."
  default     = "eu-west-1"
}

variable "prefix" {
    type        = string
    description = "Prefix for all resource names"
}

variable "BUCKET_NAME" {
  description = "Target bucket name"
  type        = string
  default     = "pgr301-couch-explorers"
}

variable "ALARM_MAIL" {
  description = "E-mail receiving the alarm"
  type        = string
  default     = "lola003@student.kristiania.no"
}

variable "threshold" {
  description = "Threshold for setting off alarm in seconds"
  type        = number
  default     = 5
}