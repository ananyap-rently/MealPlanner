import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "list", "template", "newIngredient"]

  connect() {
    this.index = this.listTarget.querySelectorAll('.ingredient-row').length || 0
    console.log("Ingredients controller connected")
    console.log("Initial index:", this.index)
  }

  add(event) {
    event.preventDefault()
    console.log("Add button clicked")
    
    const select = this.selectTarget
    const selectedOption = select.options[select.selectedIndex]
    
    if (!selectedOption || selectedOption.value === "") {
      alert("Please select an ingredient from the dropdown")
      return
    }

    const id = selectedOption.value
    const name = selectedOption.text
    
    console.log(`Adding ingredient: ${name} (ID: ${id})`)
    this.insertIngredient(id, name, false)
    
    select.selectedIndex = 0
  }

  addNew(event) {
    event.preventDefault()
    console.log("Add New button clicked")
    
    const name = this.newIngredientTarget.value.trim()
    
    if (name === "") {
      alert("Please enter an ingredient name")
      return
    }

    console.log(`Adding new ingredient: ${name}`)
    this.insertIngredient(null, name, true)
    this.newIngredientTarget.value = ""
  }

  insertIngredient(id, name, isNew = false) {
    console.log(`Inserting ingredient - ID: ${id}, Name: ${name}, IsNew: ${isNew}`)
    
    const placeholderText = this.listTarget.querySelector('p')
    if (placeholderText) {
      placeholderText.remove()
    }
    
    let html = this.templateTarget.innerHTML
    html = html.replace(/INDEX/g, this.index)
    html = html.replace(/INGREDIENT_NAME/g, name)

    if (isNew) {
      const oldInput = `name="recipe[recipe_ingredients_attributes][${this.index}][ingredient_id]" value="INGREDIENT_ID"`
      const newInput = `name="recipe[recipe_ingredients_attributes][${this.index}][new_ingredient_name]" value="${this.escapeHtml(name)}"`
      html = html.replace(oldInput, newInput)
    } else {
      html = html.replace(/INGREDIENT_ID/g, id)
    }

    this.listTarget.insertAdjacentHTML("beforeend", html)
    this.index++
    console.log("Ingredient added successfully. New index:", this.index)
  }

  remove(event) {
    event.preventDefault()
    console.log("Remove button clicked (new ingredient)")
    
    const row = event.target.closest(".ingredient-row")
    if (row) {
      row.remove()
      console.log("Ingredient removed")
      
      if (this.listTarget.children.length === 0) {
        this.listTarget.innerHTML = '<p style="color: #6c757d; margin: 0; font-style: italic;">No ingredients added yet. Select from dropdown or add new below.</p>'
      }
    }
  }

  removeExisting(event) {
    event.preventDefault()
    console.log("Remove button clicked (existing ingredient)")
    
    const row = event.target.closest(".ingredient-row")
    if (row) {
      const destroyField = row.querySelector('.destroy-field')
      if (destroyField) {
        destroyField.value = '1'
      }
      row.style.display = 'none'
      console.log("Existing ingredient marked for deletion")
    }
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}