terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.75"
    }
  }

  required_version = ">= 1.9.0"
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "role" {
  name = "Kendra-Role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "kendra.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "policy" {
  name = "Kendra-Policy"
  role = aws_iam_role.role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_kendra_index" "example" {
  name     = "example"
  role_arn = aws_iam_role.role.arn

  document_metadata_configuration_updates {
    name = "_authors"
    type = "STRING_LIST_VALUE"
    search {
      displayable = false
      facetable   = false
      searchable  = false
      sortable    = false
    }
    relevance {
      importance = 1
    }
  }

  document_metadata_configuration_updates {
    name = "_category"
    type = "STRING_VALUE"
    search {
      displayable = false
      facetable   = false
      searchable  = false
      sortable    = true
    }
    relevance {
      importance            = 1
      values_importance_map = {}
    }
  }

  document_metadata_configuration_updates {
    name = "_created_at"
    type = "DATE_VALUE"
    search {
      displayable = false
      facetable   = false
      searchable  = false
      sortable    = true
    }
    relevance {
      freshness  = false
      importance = 1
      duration   = "25920000s"
      rank_order = "ASCENDING"
    }
  }

  document_metadata_configuration_updates {
    name = "_data_source_id"
    type = "STRING_VALUE"
    search {
      displayable = false
      facetable   = false
      searchable  = false
      sortable    = true
    }
    relevance {
      importance            = 1
      values_importance_map = {}
    }
  }

  document_metadata_configuration_updates {
    name = "_document_title"
    type = "STRING_VALUE"
    search {
      displayable = true
      facetable   = false
      searchable  = true
      sortable    = true
    }
    relevance {
      importance            = 2
      values_importance_map = {}
    }
  }

  document_metadata_configuration_updates {
    name = "_excerpt_page_number"
    type = "LONG_VALUE"
    search {
      displayable = false
      facetable   = false
      searchable  = false
      sortable    = false
    }
    relevance {
      importance = 2
      rank_order = "ASCENDING"
    }
  }

  document_metadata_configuration_updates {
    name = "_faq_id"
    type = "STRING_VALUE"
    search {
      displayable = false
      facetable   = false
      searchable  = false
      sortable    = true
    }
    relevance {
      importance            = 1
      values_importance_map = {}
    }
  }

  document_metadata_configuration_updates {
    name = "_file_type"
    type = "STRING_VALUE"
    search {
      displayable = false
      facetable   = false
      searchable  = false
      sortable    = true
    }
    relevance {
      importance            = 1
      values_importance_map = {}
    }
  }

  document_metadata_configuration_updates {
    name = "_language_code"
    type = "STRING_VALUE"
    search {
      displayable = false
      facetable   = false
      searchable  = false
      sortable    = true
    }
    relevance {
      importance            = 1
      values_importance_map = {}
    }
  }

  document_metadata_configuration_updates {
    name = "_last_updated_at"
    type = "DATE_VALUE"
    search {
      displayable = false
      facetable   = false
      searchable  = false
      sortable    = true
    }
    relevance {
      freshness  = false
      importance = 1
      duration   = "25920000s"
      rank_order = "ASCENDING"
    }
  }

  document_metadata_configuration_updates {
    name = "_source_uri"
    type = "STRING_VALUE"
    search {
      displayable = true
      facetable   = false
      searchable  = false
      sortable    = false
    }
    relevance {
      importance            = 1
      values_importance_map = {}
    }
  }

  document_metadata_configuration_updates {
    name = "_tenant_id"
    type = "STRING_VALUE"
    search {
      displayable = false
      facetable   = false
      searchable  = false
      sortable    = true
    }
    relevance {
      importance            = 1
      values_importance_map = {}
    }
  }

  document_metadata_configuration_updates {
    name = "_version"
    type = "STRING_VALUE"
    search {
      displayable = false
      facetable   = false
      searchable  = false
      sortable    = true
    }
    relevance {
      importance            = 1
      values_importance_map = {}
    }
  }

  document_metadata_configuration_updates {
    name = "_view_count"
    type = "LONG_VALUE"
    search {
      displayable = false
      facetable   = false
      searchable  = false
      sortable    = true
    }
    relevance {
      importance = 1
      rank_order = "ASCENDING"
    }
  }
}