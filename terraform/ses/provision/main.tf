# Copyright 2020 Pivotal Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http:#www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#resource "aws_ses_domain_identity" "domain" {
#  domain = var.domain
#}

#resource "aws_ses_domain_dkim" "dkim" {
#  domain = aws_ses_domain_identity.domain.domain
#}

data "aws_route53_zone" "datagov_us" {
  name = var.domain
}

resource "aws_ses_domain_identity" "datagov_us" {
  domain = var.domain
}

resource "aws_route53_record" "datagov_us_amazonses_verification_record" {
  zone_id = data.aws_route53_zone.datagov_us.zone_id
  name    = "_amazonses.${aws_ses_domain_identity.datagov_us.id}"
  type    = "TXT"
  ttl     = "600"
  records = [aws_ses_domain_identity.datagov_us.verification_token]
}

resource "aws_ses_domain_identity_verification" "datagov_us_verification" {
  domain = aws_ses_domain_identity.datagov_us.id

  depends_on = [aws_route53_record.datagov_us_amazonses_verification_record]
}