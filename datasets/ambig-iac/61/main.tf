provider "aws" {
  region = "us-east-1"
}


resource "aws_route53_traffic_policy" "example" {
  name     = "example"
  comment  = "example comment"
  document = <<EOF
{
  "AWSPolicyFormatVersion": "2015-10-01",
  "RecordType": "A",
  "Endpoints": {
    "endpoint-start-NkPh": {
      "Type": "value",
      "Value": "10.0.0.2"
    }
  },
  "StartEndpoint": "endpoint-start-NkPh"
}
EOF
}