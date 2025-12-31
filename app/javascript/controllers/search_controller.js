import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "card"]

  connect() {
    console.log("Search controller connected")
  }

  filter() {
    const query = this.inputTarget.value.toLowerCase().trim()
    
    this.cardTargets.forEach(card => {
      const title = card.dataset.title.toLowerCase()
      const tags = card.dataset.tags.toLowerCase()
      
      // Search in both title and tags
      const matches = title.includes(query) || tags.includes(query)
      
      if (matches || query === "") {
        card.style.display = "block"
      } else {
        card.style.display = "none"
      }
    })
    
    // Show/hide empty state
    this.updateEmptyState(query)
  }

  updateEmptyState(query) {
    const visibleCards = this.cardTargets.filter(card => card.style.display !== "none")
    const emptyState = document.getElementById("no-results")
    
    if (visibleCards.length === 0 && query !== "") {
      if (!emptyState) {
        const container = document.querySelector(".recipes-grid")
        const message = document.createElement("div")
        message.id = "no-results"
        message.className = "empty-state"
        message.innerHTML = `<p>No recipes found matching "${query}"</p>`
        container.after(message)
      }
    } else {
      if (emptyState) {
        emptyState.remove()
      }
    }
  }

  clear() {
    this.inputTarget.value = ""
    this.filter()
    this.inputTarget.focus()
  }
}