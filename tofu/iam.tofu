resource "aws_iam_openid_connect_provider" "github_actions" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:unasuke/draft-chamber:*"]
    }
  }
}

resource "aws_iam_role" "push_ecr" {
  name               = "PushECRFromGitHubActions"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
}

resource "aws_iam_role_policy" "push_ecr" {
  role   = aws_iam_role.push_ecr.id
  policy = data.aws_iam_policy_document.push_ecr.json
}

data "aws_iam_policy_document" "push_ecr" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "sts:GetServiceBearerToken",
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
    ]
    resources = [
      aws_ecr_repository.draft_chamber.arn,
    ]
  }
}

resource "aws_iam_user" "lightsail" {
  name = "Lightsail"
}

resource "aws_iam_user" "draft_chamber_app_production" {
  name = "DraftChamberAppProduction"
}

resource "aws_iam_user_policy" "draft_chamber_app_production" {
  user   = aws_iam_user.draft_chamber_app_production.name
  policy = data.aws_iam_policy_document.draft_chamber_app_production.json
}

data "aws_iam_policy_document" "draft_chamber_app_production" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.draft_chamber_production.arn,
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
    ]
    resources = [
      "${aws_s3_bucket.draft_chamber_production.arn}/*",
    ]
  }
}
