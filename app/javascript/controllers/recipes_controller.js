// app/javascript/controllers/recipes_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["grid", "emptyState"]

  connect() {
    console.log("Recipes controller connected")
    this.loadRecipes()
  }

  async loadRecipes() {
    try {
      const apiController = this.getApiController()
      const response = await apiController.get('/api/v1/recipes')  // ← NOW using API controller!
      
      if (!response.ok) throw new Error('Failed to load recipes')

      const recipes = await response.json()
      this.renderRecipes(recipes)
    } catch (error) {
      console.error('Error loading recipes:', error)
      this.showError('Failed to load recipes')
    }
  }

  renderRecipes(recipes) {
    if (recipes.length === 0) {
      this.showEmptyState()
      return
    }

    this.gridTarget.innerHTML = recipes.map(recipe => this.recipeCardHTML(recipe)).join('')
  }

  recipeCardHTML(recipe) {
    const tags = recipe.tags?.map(tag => 
      `<span class="tag">${tag.tag_name}</span>`
    ).join('') || ''

    const tagsHTML = tags ? `<div class="tags">${tags}</div>` : ''

    return `
      <div class="recipe-card" 
           data-search-target="card"
           data-title="${recipe.title}"
           data-tags="${recipe.tags?.map(t => t.tag_name).join(' ') || ''}">
        <h2><a href="/recipes/${recipe.id}">${recipe.title}</a></h2>
        <div class="recipe-meta">
          <p><strong>Prep Time:</strong> ${recipe.prep_time} mins</p>
          <p><strong>Servings:</strong> ${recipe.servings}</p>
        </div>
        ${tagsHTML}
        <div class="recipe-actions">
          <a href="/recipes/${recipe.id}" class="btn btn-view">View</a>
          <a href="/recipes/${recipe.id}/edit" class="btn btn-edit">Edit</a>
          <button 
            type="button" 
            class="btn btn-delete" 
            data-action="click->recipes#delete" 
            data-recipe-id="${recipe.id}">
            Delete
          </button>
        </div>
      </div>
    `
  }

  async delete(event) {
    const recipeId = event.target.dataset.recipeId
    
    if (!confirm('Are you sure you want to delete this recipe?')) {
      return
    }

    try {
      const apiController = this.getApiController()
      const response = await apiController.delete(`/api/v1/recipes/${recipeId}`)
       if (response.status === 403) {
          const data = await response.json()
          alert(data.error || "You are not authorized to delete this recipe.")
          return
        }
        
      if (!response.ok) throw new Error('Failed to delete recipe')
        alert('Recipe deleted successfully!')
      // Remove card from DOM
      const card = event.target.closest('.recipe-card')
      card.remove()

      // Check if grid is empty
      if (this.gridTarget.children.length === 0) {
        this.showEmptyState()
      }

    } catch (error) {
      console.error('Error deleting recipe:', error)
      alert('Failed to delete recipe. Please try again.')
    }
  }

  showEmptyState() {
    if (this.hasEmptyStateTarget) {
      this.emptyStateTarget.style.display = 'block'
      this.gridTarget.style.display = 'none'
    }
  }

  showError(message) {
    alert(message)
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ''
  }
  getApiController() {
    const apiController = this.application.getControllerForElementAndIdentifier(
      document.body,
      "api"
    )
    
    if (!apiController) {
      throw new Error('API controller not found. Make sure data-controller="api" is on body element.')
    }
    
    return apiController
  }
}