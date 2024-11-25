variable "region"{
  description = "The AWS region to deploy resources in."
  default     = "eu-west-1"
}

variable "BUCKET_NAME"{
  description = "target bucket name"
  type        = string
  default     = "pgr301-couch-explorers"
}

variable "ALARM_MAIL"{
  description = "E-mail receiving the alarm"
  type        = string
  default     = "lola003@student.kristiania.no"
}