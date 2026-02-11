import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["link"]

  async downloadAll(event) {
    event.preventDefault()
    const button = event.currentTarget
    button.disabled = true

    for (const link of this.linkTargets) {
      const a = document.createElement("a")
      a.href = link.href
      a.download = ""
      document.body.appendChild(a)
      a.click()
      document.body.removeChild(a)
      await new Promise(resolve => setTimeout(resolve, 500))
    }

    button.disabled = false
  }
}
