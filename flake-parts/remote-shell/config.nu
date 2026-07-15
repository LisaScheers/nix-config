$env.config = {
  show_banner: false
  history: {
    file_format: "sqlite"
    max_size: 100_000
    sync_on_enter: true
  }
}

source starship.nu
