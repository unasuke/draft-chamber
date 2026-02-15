terraform {
  backend "s3" {
    bucket       = "draft-chamber-tfstate-136517c0-ceb5-4d71-be3d-3028b780719a"
    key          = "draft-chamber.tfstate"
    region       = "ap-northeast-1"
    use_lockfile = true
  }
}
