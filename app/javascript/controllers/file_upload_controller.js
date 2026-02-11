import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "info"]

  select() {
    const file = this.inputTarget.files[0]
    if (file) {
      const size = this.formatSize(file.size)
      this.infoTarget.textContent = `${file.name} (${size})`
    } else {
      this.infoTarget.textContent = ""
    }
  }

  formatSize(bytes) {
    if (bytes < 1024) return `${bytes} B`
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
  }
}
