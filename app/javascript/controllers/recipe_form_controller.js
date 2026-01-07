// app/javascript/controllers/recipe_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "errors", "submitBtn"]
  static values = {
    recipeId: String,
    mode: String // 'new' or 'edit'
  }

  connect() {
    console.log("Recipe form controller connected")
    if (this.modeValue === 'edit') {
      this.loadRecipe()
    }
  }

  async loadRecipe() {
    try {
      const response = await fetch(`/api/v1/recipes/${this.recipeIdValue}`, {
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': this.csrfToken
        }
      })

      if (!response.ok) throw new Error('Failed to load recipe')

      const data = await response.json()
      this.populateForm(data)
    } catch (error) {
      console.error('Error loading recipe:', error)
      this.showError(['Failed to load recipe data'])
    }
  }

  populateForm(recipe) {
    // Populate basic fields
    const titleInput = this.formTarget.querySelector('[name="recipe[title]"]')
    const instructionsInput = this.formTarget.querySelector('[name="recipe[instructions]"]')
    const prepTimeInput = this.formTarget.querySelector('[name="recipe[prep_time]"]')
    const servingsInput = this.formTarget.querySelector('[name="recipe[servings]"]')

    if (titleInput) titleInput.value = recipe.title || ''
    if (instructionsInput) instructionsInput.value = recipe.instructions || ''
    if (prepTimeInput) prepTimeInput.value = recipe.prep_time || ''
    if (servingsInput) servingsInput.value = recipe.servings || ''

    // Populate tags
    if (recipe.tags && recipe.tags.length > 0) {
      recipe.tags.forEach(tag => {
        const checkbox = this.formTarget.querySelector(`input[type="checkbox"][value="${tag.id}"]`)
        if (checkbox) checkbox.checked = true
      })
    }

    // Note: Ingredients are handled by the ingredients controller
  }

  async submit(event) {
    event.preventDefault()
    
    this.clearErrors()
    this.submitBtnTarget.disabled = true
    this.submitBtnTarget.textContent = 'Saving...'

    const formData = new FormData(this.formTarget)
    const recipeData = this.buildRecipeData(formData)

    try {
      const url = this.modeValue === 'edit' 
        ? `/api/v1/recipes/${this.recipeIdValue}`
        : '/api/v1/recipes'
      
      const method = this.modeValue === 'edit' ? 'PATCH' : 'POST'

      const response = await fetch(url, {
        method: method,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': this.csrfToken
        },
        body: JSON.stringify({ recipe: recipeData })
      })

      const data = await response.json()

      if (!response.ok) {
        this.showError(data.errors || ['An error occurred'])
        return
      }

      // Success - redirect to recipe show page
      window.location.href = `/recipes/${data.id}`

    } catch (error) {
      console.error('Error saving recipe:', error)
      this.showError(['Failed to save recipe. Please try again.'])
    } finally {
      this.submitBtnTarget.disabled = false
      this.submitBtnTarget.textContent = this.modeValue === 'edit' ? 'Update Recipe' : 'Create Recipe'
    }
  }

  buildRecipeData(formData) {
    const data = {
      title: formData.get('recipe[title]'),
      instructions: formData.get('recipe[instructions]'),
      prep_time: formData.get('recipe[prep_time]'),
      servings: formData.get('recipe[servings]'),
      new_tag_name: formData.get('recipe[new_tag_name]'),
      tag_ids: formData.getAll('recipe[tag_ids][]').filter(id => id !== ''),
      recipe_ingredients_attributes: []
    }

    // Collect recipe ingredients
    const ingredientIds = formData.getAll('recipe[recipe_ingredients_attributes][][ingredient_id]')
    const quantities = formData.getAll('recipe[recipe_ingredients_attributes][][quantity]')
    const units = formData.getAll('recipe[recipe_ingredients_attributes][][unit]')
    const ids = formData.getAll('recipe[recipe_ingredients_attributes][][id]')
    const destroys = formData.getAll('recipe[recipe_ingredients_attributes][][_destroy]')

    // Build recipe_ingredients_attributes array
    ingredientIds.forEach((ingredientId, index) => {
      const ingredient = {
        ingredient_id: ingredientId,
        quantity: quantities[index],
        unit: units[index]
      }

      if (ids[index]) {
        ingredient.id = ids[index]
      }

      if (destroys[index] === 'true') {
        ingredient._destroy = true
      }

      data.recipe_ingredients_attributes.push(ingredient)
    })

    return data
  }

  showError(messages) {
    if (!this.hasErrorsTarget) return

    const errorHtml = `
      <div class="error-messages">
        <h3>${messages.length} error(s) prohibited this recipe from being saved:</h3>
        <ul>
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