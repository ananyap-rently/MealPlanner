// app/javascript/controllers/recipes_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["grid", "emptyState", "allRecipesTab", "myRecipesTab"]

  connect() {
    console.log("Recipes controller connected")
    this.currentView = "all"
    this.loadRecipes()
  }

  loadRecipes() {
    if (this.currentView === "all") {
      this.loadAllRecipes()
    } else {
      this.loadMyRecipes()
    }
  }

  async loadAllRecipes() {
    this.currentView = "all"
    this.updateTabStyles("all")
    
    try {
      const apiController = this.getApiController()
      const response = await apiController.get('/api/v1/recipes')
      
      if (!response.ok) throw new Error('Failed to load recipes')

      const recipes = await response.json()
      this.renderRecipes(recipes)
      this.updateEmptyStateMessage("No recipes yet. Create your first recipe!")
    } catch (error) {
      console.error('Error loading recipes:', error)
      this.showError('Failed to load recipes')
    }
  }

  async loadMyRecipes() {
    this.currentView = "my"
    this.updateTabStyles("my")
    
    try {
      const apiController = this.getApiController()
      const response = await apiController.get('/api/v1/recipes/my_recipes')
      
      if (response.status === 401) {
        alert('Please log in to view your recipes')
        this.loadAllRecipes()
        return
      }
      
      if (!response.ok) throw new Error('Failed to load your recipes')

      const recipes = await response.json()
      this.renderRecipes(recipes)
      this.updateEmptyStateMessage("You haven't created any recipes yet. Create one now!")
    } catch (error) {
      console.error('Error loading my recipes:', error)
      this.showError('Failed to load your recipes')
    }
  }

  updateTabStyles(activeView) {
    if (this.hasAllRecipesTabTarget) {
      this.allRecipesTabTarget.classList.toggle('active', activeView === 'all')
    }
    if (this.hasMyRecipesTabTarget) {
      this.myRecipesTabTarget.classList.toggle('active', activeView === 'my')
    }
  }

  updateEmptyStateMessage(message) {
    const messageElement = document.getElementById("empty-message")
    if (messageElement) {
      messageElement.textContent = message
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

    // Get current user ID from data attribute
    const currentUserId = parseInt(this.element.dataset.currentUserId)
    const isOwnRecipe = recipe.user && recipe.user.id === currentUserId
    const badgeHTML = isOwnRecipe ? '<span class="my-recipe-badge">My Recipe</span>' : ''

    // Format user info: "Name (email)"
    const userName = recipe.user?.name || 'Unknown User'
    const userEmail = recipe.user?.email || ''
    const userInfo = userEmail ? `${userName} (${userEmail})` : userName

    return `
      <div class="recipe-card" 
           data-search-target="card"
           data-title="${recipe.title}"
           data-tags="${recipe.tags?.map(t => t.tag_name).join(' ') || ''}"
           ${isOwnRecipe ? 'data-own-recipe="true"' : ''}>
        <div class="recipe-card-header">
          <h2><a href="/recipes/${recipe.id}">${recipe.title}</a></h2>
          ${badgeHTML}
        </div>
        <div class="recipe-user-info">
          <p class="user-details">${userInfo}</p>
        </div>
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