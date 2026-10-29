# Provider simulato: nessuna credenziale e nessuna risorsa AWS richiesta.
mock_provider "aws" {}

variables {
  aws_region = "us-east-1"
  student_id = "test01"
  owner      = "Studente Test"
}

run "secure_storage_plan" {
  command = plan

  assert {
    condition = (
      aws_s3_bucket_public_access_block.documents.block_public_acls &&
      aws_s3_bucket_public_access_block.documents.block_public_policy &&
      aws_s3_bucket_public_access_block.documents.ignore_public_acls &&
      aws_s3_bucket_public_access_block.documents.restrict_public_buckets
    )
    error_message = "Tutte le opzioni Block Public Access devono essere attive."
  }

  assert {
    condition     = aws_s3_bucket_versioning.documents.versioning_configuration[0].status == "Enabled"
    error_message = "Il versioning deve essere Enabled."
  }

  assert {
    condition = alltrue([
      for rule in aws_s3_bucket_server_side_encryption_configuration.documents.rule :
      rule.apply_server_side_encryption_by_default[0].sse_algorithm == "AES256"
    ])
    error_message = "La cifratura deve usare SSE-S3 (AES256)."
  }

  assert {
    condition     = !aws_s3_bucket.documents.force_destroy
    error_message = "Il bucket non deve cancellare automaticamente i dati al destroy."
  }

  assert {
    condition = (
      aws_s3_bucket.documents.tags["Owner"] == "Studente Test" &&
      aws_s3_bucket.documents.tags["CostCenter"] == "didattica"
    )
    error_message = "I tag Owner e CostCenter devono essere valorizzati."
  }
}

run "reject_region_outside_learner_lab" {
  command = plan

  variables {
    aws_region = "eu-west-1"
  }

  expect_failures = [var.aws_region]
}

run "reject_invalid_student_id" {
  command = plan

  variables {
    student_id = "Nome Con Spazi"
  }

  expect_failures = [var.student_id]
}
