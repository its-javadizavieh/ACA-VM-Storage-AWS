variable "aws_region" {
  description = "Regione consentita dal Learner Lab."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = contains(["us-east-1", "us-west-2"], var.aws_region)
    error_message = "Usare us-east-1 oppure us-west-2."
  }
}

variable "student_id" {
  description = "Identificativo studente usato nel prefisso del bucket."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,11}$", var.student_id))
    error_message = "Usare 3-12 caratteri: minuscole, numeri o trattini; iniziare con una lettera."
  }
}

variable "owner" {
  description = "Responsabile delle risorse, riportato nei tag."
  type        = string

  validation {
    condition     = length(trimspace(var.owner)) >= 3 && length(var.owner) <= 50
    error_message = "Owner deve contenere tra 3 e 50 caratteri e non essere vuoto."
  }
}
