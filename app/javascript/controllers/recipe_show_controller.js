// app/javascript/controllers/recipe_show_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "commentsList", "commentForm", "commentInput"]
  static values = {
    recipeId: String
  }

  connect() {
    console.log("Recipe show controller connected")
    this.loadRecipe()
  }
  // --- API ACCESSOR ---
  getApiController() {
    const apiController = this.application.getControllerForElementAndIdentifier(
      document.body,
      "api"
    )
    if (!apiController) {
      throw new Error('API controller not found. Ensure data-controller="api" is on the <body> element.')
    }
    return apiController
  }

  
  async loadRecipe() {
    try {
      const api = this.getApiController()
      const response = await api.get(`/api/v1/recipes/${this.recipeIdValue}`)

      if (!response.ok) throw new Error('Failed to load recipe')

      const recipe = await response.json()
      this.renderRecipe(recipe)
    } catch (error) {
      console.error('Error loading recipe:', error)
      this.showError('Failed to load recipe')
    }
  }

  renderRecipe(recipe) {
    const tags = recipe.tags?.map(tag => 
      `<span class="tag">${tag.tag_name}</span>`
    ).join('') || ''

    const tagsSection = tags ? `
      <div class="meta-item">
        <strong>Tags:</strong>
        <div class="tags">${tags}</div>
      </div>
    ` : ''

    // Build ingredients list with quantities and units
    let ingredientsHTML = '<p class="empty-message">No ingredients added yet.</p>'
    
    if (recipe.recipe_ingredients && recipe.recipe_ingredients.length > 0) {
      const ingredients = recipe.recipe_ingredients.map(ri => {
        // Find the ingredient details
        const ingredient = recipe.ingredients?.find(ing => ing.id === ri.ingredient_id)
        const ingredientName = ingredient?.name || 'Unknown ingredient'
        
        return `<li>
          <strong>${ri.quantity} ${ri.unit}</strong> ${ingredientName}
        </li>`
      }).join('')
      
      ingredientsHTML = `<ul class="ingredients-list">${ingredients}</ul>`
    }

    this.contentTarget.innerHTML = `
      <div class="recipe-header">
        <div class="header-content">
          <h1>${recipe.title}</h1>
          <p class="author-info">
            By ${recipe.user?.email || 'Unknown'} • Created ${this.formatDate(recipe.created_at)}
          </p>
        </div>
        <div class="header-actions">
          <a href="/recipes/${recipe.id}/edit" class="btn btn-edit">Edit</a>
          <button 
            type="button" 
            class="btn btn-delete"
            data-action="click->recipe-show#delete">
            Delete
          </button>
        </div>
      </div>

      <div class="recipe-meta">
        <div class="meta-item">
          <strong>Prep Time:</strong>
          <span>${recipe.prep_time} minutes</span>
        </div>
        <div class="meta-item">
          <strong>Servings:</strong>
          <span>${recipe.servings} servings</span>
        </div>
        ${tagsSection}
      </div>

      <div class="recipe-content">
        <div class="content-section">
          <h2>Ingredients</h2>
          ${ingredientsHTML}
        </div>

        <div class="content-section">
          <h2>Instructions</h2>
          <div class="instructions">
            ${this.formatInstructions(recipe.instructions)}
          </div>
        </div>
      </div>
    `

    // Render comments
    this.renderComments(recipe.comments || [])
  }

  renderComments(comments) {
    const commentsHTML = comments.length > 0 
      ? comments.map(comment => this.commentHTML(comment)).join('')
      : '<p class="empty-message">No comments yet. Be the first to comment!</p>'

    this.commentsListTarget.innerHTML = commentsHTML
  }

  commentHTML(comment) {
    const canDelete = comment.user?.id === this.currentUserId

    const deleteBtn = canDelete ? `
      <div class="comment-actions">
        <button 
          type="button" 
          class="btn-delete-comment"
          data-action="click->recipe-show#deleteComment"
          data-comment-id="${comment.id}">
          Delete
        </button>
      </div>
    ` : ''

    return `
      <div class="comment" data-comment-id="${comment.id}">
        <div class="comment-header">
          <strong>${comment.user?.email || 'Unknown'}</strong>
          <span class="comment-date">${this.timeAgo(comment.created_at)} ago</span>
        </div>
        <div class="comment-content">
          ${comment.content}
        </div>
        ${deleteBtn}
      </div>
    `
  }

  async submitComment(event) {
    event.preventDefault()

    const content = this.commentInputTarget.value.trim()
    if (!content) {
      alert('Please enter a comment')
      return
    }

    try {
      const api = this.getApiController()
      // Note: your api.post likely handles JSON.stringify internally
      const response = await api.post(`/api/v1/recipes/${this.recipeIdValue}/comments`, { 
        comment: { content } 
      })

      if (!response.ok) {
        const data = await response.json()
        throw new Error(data.errors?.[0] || 'Failed to post comment')
      }

      const comment = await response.json()
      
      // Add comment to list
      const emptyMsg = this.commentsListTarget.querySelector('.empty-message')
      if (emptyMsg) {
        emptyMsg.remove()
      }

      this.commentsListTarget.insertAdjacentHTML('beforeend', this.commentHTML(comment))
      
      // Clear form
      this.commentInputTarget.value = ''

    } catch (error) {
      console.error('Error posting comment:', error)
      alert(error.message || 'Failed to post comment')
    }
  }

  async deleteComment(event) {
    const commentId = event.target.dataset.commentId

    if (!confirm('Are you sure you want to delete this comment?')) {
      return
    }

    try {
      const api = this.getApiController()
      const response = await api.delete(`/api/v1/comments/${commentId}`)

      if (!response.ok) throw new Error('Failed to delete comment')

      // Remove from DOM
      const commentEl = this.commentsListTarget.querySelector(`[data-comment-id="${commentId}"]`)
      commentEl.remove()

      // Show empty message if no comments left
      if (this.commentsListTarget.children.length === 0) {
        this.commentsListTarget.innerHTML = '<p class="empty-message">No comments yet. Be the first to comment!</p>'
      }

    } catch (error) {
      console.error('Error deleting comment:', error)
      alert('Failed to delete comment')
    }
  }

  async delete() {
    if (!confirm('Are you sure you want to delete this recipe?')) {
      return
    }

    try {
      const api = this.getApiController()
      const response = await api.delete(`/api/v1/recipes/${this.recipeIdValue}`)

      if (!response.ok) throw new Error('Failed to delete recipe')

      window.location.href = '/recipes'

    } catch (error) {
      console.error('Error deleting recipe:', error)
      alert('Failed to delete recipe')
    }
  }

  formatDate(dateString) {
    const date = new Date(dateString)
    return date.toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })
  }

  formatInstructions(text) {
    return text.split('\n').map(p => p.trim()).filter(p => p).map(p => `<p>${p}</p>`).join('')
  }

  timeAgo(dateString) {
    const seconds = Math.floor((new Date() - new Date(dateString)) / 1000)
    
    let interval = seconds / 31536000
    if (interval > 1) return Math.floor(interval) + " years"
    
    interval = seconds / 2592000
    if (interval > 1) return Math.floor(interval) + " months"
    
    interval = seconds / 86400
    if (interval > 1) return Math.floor(interval) + " days"
    
    interval = seconds / 3600
    if (interval > 1) return Math.floor(interval) + " hours"
    
    interval = seconds / 60
    if (interval > 1) return Math.floor(interval) + " minutes"
    
    return Math.floor(seconds) + " seconds"
  }

  showError(message) {
    alert(message)
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ''
  }

  get currentUserId() {
    return document.body.dataset.currentUserId
  }
}