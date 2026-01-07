// app/javascript/controllers/ingredients_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "list", "template", "newIngredient"]

  connect() {
    console.log("Ingredients controller connected")
    this.index = this.listTarget.querySelectorAll('.ingredient-row').length
  }

  async add(event) {
    event.preventDefault()
    
    const selectedId = this.selectTarget.value
    if (!selectedId) {
      alert('Please select an ingredient')
      return
    }

    const selectedOption = this.selectTarget.options[this.selectTarget.selectedIndex]
    const ingredientName = selectedOption.text

    this.addIngredientToList(selectedId, ingredientName)
    this.selectTarget.value = ''
  }

  async addNew(event) {
    event.preventDefault()
    
    const ingredientName = this.newIngredientTarget.value.trim()
    if (!ingredientName) {
      alert('Please enter an ingredient name')
      return
    }

    try {
      // Create new ingredient via API
      const response = await fetch('/api/v1/ingredients', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': this.csrfToken
        },
        body: JSON.stringify({ ingredient: { name: ingredientName } })
      })

      if (!response.ok) {
        const data = await response.json()
        throw new Error(data.errors?.[0] || 'Failed to create ingredient')
      }

      const ingredient = await response.json()
      
      // Add to dropdown
      const option = new Option(ingredient.name, ingredient.id)
      this.selectTarget.add(option)
      
      // Add to selected list
      this.addIngredientToList(ingredient.id, ingredient.name)
      
      // Clear input
      this.newIngredientTarget.value = ''

    } catch (error) {
      console.error('Error creating ingredient:', error)
      alert(error.message || 'Failed to create ingredient')
    }
  }

  addIngredientToList(ingredientId, ingredientName) {
    // Check if ingredient already added
    const existingInputs = this.listTarget.querySelectorAll('input[name*="[ingredient_id]"]')
    for (let input of existingInputs) {
      if (input.value === ingredientId) {
        alert('This ingredient is already added')
        return
      }
    }

    // Remove empty message if exists
    const emptyMessage = this.listTarget.querySelector('p')
    if (emptyMessage) {
      emptyMessage.remove()
    }

    // Clone template
    const template = this.templateTarget.content.cloneNode(true)
    const row = template.querySelector('.ingredient-row')

    // Replace placeholders
    row.innerHTML = row.innerHTML
      .replace(/INDEX/g, this.index)
      .replace(/INGREDIENT_ID/g, ingredientId)
      .replace(/INGREDIENT_NAME/g, ingredientName)

    this.listTarget.appendChild(row)
    this.index++
  }

  remove(event) {
    event.preventDefault()
    const row = event.target.closest('.ingredient-row')
    row.remove()

    // Show empty message if no ingredients left
    if (this.listTarget.querySelectorAll('.ingredient-row').length === 0) {
      this.listTarget.innerHTML = '<p style="color: #6c757d; margin: 0; font-style: italic;">No ingredients added yet. Select from dropdown or add new below.</p>'
    }
  }

  removeExisting(event) {
    event.preventDefault()
    const row = event.target.closest('.ingredient-row')
    const destroyField = row.querySelector('.destroy-field')
    
    if (destroyField) {
      // Mark for destruction (for existing records)
      destroyField.value = 'true'
      row.style.display = 'none'
    } else {
      // Remove from DOM (for new records)
      row.remove()
    }

    // Show empty message if no visible ingredients left
    const visibleRows = Array.from(this.listTarget.querySelectorAll('.ingredient-row'))
      .filter(r => r.style.display !== 'none')
    
    if (visibleRows.length === 0) {
      const emptyMsg = document.createElement('p')
      emptyMsg.style.cssText = 'color: #6c757d; margin: 0; font-style: italic;'
      emptyMsg.textContent = 'No ingredients added yet. Select from dropdown or add new below.'
      this.listTarget.appendChild(emptyMsg)
    }
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ''
  }
}