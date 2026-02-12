import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "row"]

  filter() {
    const query = this.inputTarget.value.toLowerCase()

    this.rowTargets.forEach((row) => {
      const acronym = row.querySelector("td").textContent.toLowerCase()
      row.classList.toggle("hidden", !acronym.startsWith(query))
    })
  }
}
