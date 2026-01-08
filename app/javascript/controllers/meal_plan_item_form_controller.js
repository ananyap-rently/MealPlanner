// app/javascript/controllers/meal_plan_item_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "form", "recipeSection", "itemSection", "createItemSection",
    "recipeSelect", "itemSelect", "newItemName", "newItemQuantity",
    "submitBtn", "errors"
  ]
  static values = {
    mealPlanId: String
  }

  connect() {
    console.log("Meal plan item form controller connected")
    // Initialize with Recipe option visible
    this.showRecipeOption()
  }

  showRecipeOption() {
    this.recipeSectionTarget.style.display = 'block'
    this.itemSectionTarget.style.display = 'none'
    this.createItemSectionTarget.style.display = 'none'
    
    // Clear other fields
    if (this.hasItemSelectTarget) this.itemSelectTarget.value = ''
    if (this.hasNewItemNameTarget) this.newItemNameTarget.value = ''
    if (this.hasNewItemQuantityTarget) this.newItemQuantityTarget.value = ''
  }

  showItemOption() {
    this.recipeSectionTarget.style.display = 'none'
    this.itemSectionTarget.style.display = 'block'
    this.createItemSectionTarget.style.display = 'none'
    
    // Clear other fields
    if (this.hasRecipeSelectTarget) this.recipeSelectTarget.value = ''
    if (this.hasNewItemNameTarget) this.newItemNameTarget.value = ''
    if (this.hasNewItemQuantityTarget) this.newItemQuantityTarget.value = ''
  }

  showCreateItemOption() {
    this.recipeSectionTarget.style.display = 'none'
    this.itemSectionTarget.style.display = 'none'
    this.createItemSectionTarget.style.display = 'block'
    
    // Clear other fields
    if (this.hasRecipeSelectTarget) this.recipeSelectTarget.value = ''
    if (this.hasItemSelectTarget) this.itemSelectTarget.value = ''
  }

  async submit(event) {
    event.preventDefault()
    
    this.clearErrors()
    this.submitBtnTarget.disabled = true
    this.submitBtnTarget.textContent = 'Adding...'

    const formData = new FormData(this.formTarget)
    
    // Determine which option was selected
    let plannableType = null
    let plannableId = null
    let newItemName = null
    let newItemQuantity = null

    if (this.recipeSectionTarget.style.display !== 'none' && this.recipeSelectTarget.value) {
      plannableType = 'Recipe'
      plannableId = this.recipeSelectTarget.value
    } else if (this.itemSectionTarget.style.display !== 'none' && this.itemSelectTarget.value) {
      plannableType = 'Item'
      plannableId = this.itemSelectTarget.value
    } else if (this.createItemSectionTarget.style.display !== 'none' && this.newItemNameTarget.value.trim()) {
      plannableType = 'Item'
      newItemName = this.newItemNameTarget.value.trim()
      newItemQuantity = this.newItemQuantityTarget.value.trim()
    } else {
      this.showError(['Please select a recipe, item, or create a new item'])
      this.submitBtnTarget.disabled = false
      this.submitBtnTarget.textContent = 'Add to Meal Plan'
      return
    }

    const itemData = {
      scheduled_date: formData.get('meal_plan_item[scheduled_date]'),
      meal_slot: formData.get('meal_plan_item[meal_slot]'),
      plannable_type: plannableType,
      plannable_id: plannableId
    }

    try {
      const response = await fetch(`/api/v1/meal_plans/${this.mealPlanIdValue}/meal_plan_items`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': this.csrfToken
        },
        body: JSON.stringify({ 
          meal_plan_item: itemData,
          new_item_name: newItemName,
          new_item_quantity: newItemQuantity
        })
      })

      const data = await response.json()

      if (!response.ok) {
        this.showError(data.errors || ['Failed to add item to meal plan'])
        return
      }

      // Success - redirect to meal plan show page
      window.location.href = `/meal_plans/${this.mealPlanIdValue}`

    } catch (error) {
      console.error('Error adding meal plan item:', error)
      this.showError(['Failed to add item. Please try again.'])
    } finally {
      this.submitBtnTarget.disabled = false
      this.submitBtnTarget.textContent = 'Add to Meal Plan'
    }
  }

  showError(messages) {
    if (!this.hasErrorsTarget) return

    const errorHtml = `
      <div class="alert alert-danger">
        <ul class="mb-0">
          ${messages.map(msg => `<li>${msg}</li>`).join('')}
        </ul>
      </div>
    `
    this.errorsTarget.innerHTML = errorHtml
    this.errorsTarget.scrollIntoView({ behavior: 'smooth', block: 'nearest' })
  }

  clearErrors() {
    if (this.hasErrorsTarget) {
      this.errorsTarget.innerHTML = ''
    }
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ''
  }
}