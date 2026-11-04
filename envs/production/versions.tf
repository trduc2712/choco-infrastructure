terraform {
  required_version = ">= 1.6"

  cloud {
    organization = "trduc2712"

    workspaces {
      name = "choco-production"
    }
  }

  required_providers {
    render = {
      source  = "render-oss/render"
      version = "~> 1.9"
    }

    b2 = {
      source  = "Backblaze/b2"
      version = "~> 0.14"
    }

    neon = {
      source  = "kislerdm/neon"
      version = "~> 0.18"
    }

    vercel = {
      source  = "vercel/vercel"
      version = "~> 5.25"
    }
  }
}
