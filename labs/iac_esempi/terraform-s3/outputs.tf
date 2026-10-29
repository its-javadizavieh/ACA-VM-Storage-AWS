output "bucket_name" {
  description = "Nome reale del bucket, con suffisso generato dal provider."
  value       = aws_s3_bucket.documents.id
}

output "bucket_arn" {
  description = "ARN del bucket gestito."
  value       = aws_s3_bucket.documents.arn
}

output "aws_region" {
  value = var.aws_region
}
