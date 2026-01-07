// app/javascript/controllers/meal_plan_show_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "header", "calendar", "commentsList", "commentForm", 
    "commentInput", "addItemForm", "errors"
  ]
  static values = {
    mealPlanId: String
  }

  connect() {
    console.log("Meal plan show controller connected")
    this.loadMealPlan()
  }

  async loadMealPlan() {
    try {
      const response = await fetch(`/api/v1/meal_plans/${this.mealPlanIdValue}`, {
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': this.csrfToken
        }
      })

      if (!response.ok) throw new Error('Failed to load meal plan')

      const data = await response.json()
      this.renderMealPlan(data)
    } catch (error) {
      console.error('Error loading meal plan:', error)
      this.showError('Failed to load meal plan')
    }
  }

  renderMealPlan(data) {
    const { meal_plan, items_by_date, comments } = data

    // Render header
    this.renderHeader(meal_plan)

    // Render calendar
    this.renderCalendar(meal_plan, items_by_date)

    // Render comments
    this.renderComments(comments || [])
  }

  renderHeader(mealPlan) {
    const startDate = new Date(mealPlan.start_date).toLocaleDateString('en-US', { 
      year: 'numeric', month: 'long', day: 'numeric' 
    })
    const endDate = new Date(mealPlan.end_date).toLocaleDateString('en-US', { 
      year: 'numeric', month: 'long', day: 'numeric' 
    })

    this.headerTarget.innerHTML = `
      <h1>${mealPlan.category} Meal Plan</h1>
      <p class="lead">${startDate} - ${endDate}</p>
    `
  }

  renderCalendar(mealPlan, itemsByDate) {
    const startDate = new Date(mealPlan.start_date)
    const endDate = new Date(mealPlan.end_date)
    const hasItems = Object.keys(itemsByDate).length > 0

    const addAllButton = hasItems ? `
      <button 
        type="button" 
        class="btn btn-success btn-sm"
        data-action="click->meal-plan-show#addAllToShopping">
        Add All to Shopping List
      </button>
    ` : ''

    let calendarHTML = `
      <div class="card-header d-flex justify-content-between align-items-center">
        <h4 class="mb-0">Your Meal Plan</h4>
        ${addAllButton}
      </div>
      <div class="card-body">
    `

    if (!hasItems) {
      calendarHTML += `
        <div class="text-center py-5">
          <p class="text-muted">No items added yet. Use the form on the left to start planning your meals!</p>
        </div>
      `
    } else {
      // Iterate through each date in the range
      for (let d = new Date(startDate); d <= endDate; d.setDate(d.getDate() + 1)) {
        const dateStr = d.toISOString().split('T')[0]
        const items = itemsByDate[dateStr] || []

        calendarHTML += `
          <div class="meal-day mb-4 pb-3 border-bottom">
            <h5 class="mb-3">${this.formatDate(d)}</h5>
        `

        if (items.length > 0) {
          const slots = ['breakfast', 'lunch', 'dinner', 'snack']
          
          slots.forEach(slot => {
            const slotItems = items.filter(item => item.meal_slot === slot)
            
            if (slotItems.length > 0) {
              calendarHTML += `
                <div class="meal-slot mb-3">
                  <h6 class="text-muted">${slot.charAt(0).toUpperCase() + slot.slice(1)}</h6>
                  <ul class="list-group">
              `

              slotItems.forEach(item => {
                calendarHTML += this.renderMealItem(item)
              })

              calendarHTML += `
                  </ul>
                </div>
              `
            }
          })
        } else {
          calendarHTML += '<p class="text-muted small">No items planned for this day</p>'
        }

        calendarHTML += '</div>'
      }
    }

    calendarHTML += '</div>'
    this.calendarTarget.innerHTML = calendarHTML
  }

  renderMealItem(item) {
    const badgeClass = item.plannable_type === 'Recipe' ? 'info' : 'secondary'
    let itemContent = ''

    if (item.plannable_type === 'Recipe' && item.plannable) {
      itemContent = `<strong>${item.plannable.title}</strong>`
    } else if (item.plannable_type === 'Item' && item.plannable) {
      itemContent = `<strong>${item.plannable.item_name}</strong>`
      if (item.plannable.quantity) {
        itemContent += ` <span class="text-muted">(${item.plannable.quantity})</span>`
      }
    } else {
      itemContent = '<span class="text-muted">[Deleted item]</span>'
    }

    return `
      <li class="list-group-item d-flex justify-content-between align-items-center">
        <div>
          <span class="badge bg-${badgeClass} me-2">${item.plannable_type}</span>
          ${itemContent}
        </div>
        <button 
          type="button"
          class="btn btn-sm btn-outline-danger"
          data-action="click->meal-plan-show#removeItem"
          data-item-id="${item.id}">
          Remove
        </button>
      </li>
    `
  }

  renderComments(comments) {
    const commentsHTML = comments.length > 0 
      ? comments.map(comment => this.commentHTML(comment)).join('')
      : '<p class="text-muted">No comments yet. Be the first to comment!</p>'

    this.commentsListTarget.innerHTML = commentsHTML
  }

  commentHTML(comment) {
    const canDelete = comment.user?.id === this.currentUserId

    const deleteBtn = canDelete ? `
      <button 
        type="button" 
        class="btn btn-sm btn-outline-danger"
        data-action="click->meal-plan-show#deleteComment"
        data-comment-id="${comment.id}">
        Delete
      </button>
    ` : ''

    return `
      <div class="comment mb-3 p-3 border rounded" data-comment-id="${comment.id}">
        <div class="d-flex justify-content-between align-items-start">
          <div>
            <strong>${comment.user?.email || 'Unknown'}</strong>
            <small class="text-muted d-block">
              ${this.timeAgo(comment.created_at)} ago
            </small>
          </div>
          ${deleteBtn}
        </div>
        <p class="mt-2 mb-0">${comment.content}</p>
      </div>
    `
  }

  async addItem(event) {
    event.preventDefault()
    
    const formData = new FormData(event.target)
    const itemData = {
      scheduled_date: formData.get('meal_plan_item[scheduled_date]'),
      meal_slot: formData.get('meal_plan_item[meal_slot]'),
      plannable_type: formData.get('meal_plan_item[plannable_type]'),
      plannable_id: formData.get('meal_plan_item[plannable_id]')
    }

    // Handle new item creation if needed
    const newItemName = formData.get('new_item_name')
    const newItemQuantity = formData.get('new_item_quantity')

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
        this.showError(data.errors || ['Failed to add item'])
        return
      }

      // Reload meal plan to show updated calendar
      this.loadMealPlan()
      
      // Clear form
      event.target.reset()
      this.clearErrors()

    } catch (error) {
      console.error('Error adding item:', error)
      this.showError(['Failed to add item. Please try again.'])
    }
  }

  async removeItem(event) {
    const itemId = event.target.dataset.itemId

    if (!confirm('Remove this item?')) {
      return
    }

    try {
      const response = await fetch(`/api/v1/meal_plans/${this.mealPlanIdValue}/meal_plan_items/${itemId}`, {
        method: 'DELETE',
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': this.csrfToken
        }
      })

      if (!response.ok) throw new Error('Failed to remove item')

      // Remove from DOM
      const listItem = event.target.closest('.list-group-item')
      listItem.remove()

    } catch (error) {
      console.error('Error removing item:', error)
      alert('Failed to remove item')
    }
  }

  async addAllToShopping() {
    if (!confirm('Add all items to your shopping list?')) {
      return
    }

    try {
      const response = await fetch(
        `/api/v1/meal_plans/${this.mealPlanIdValue}/meal_plan_items/add_to_shopping_list`,
        {
          method: 'POST',
          headers: {
            'Accept': 'application/json',
            'X-CSRF-Token': this.csrfToken
          }
        }
      )

      if (!response.ok) throw new Error('Failed to add to shopping list')

      alert('All items added to shopping list!')

    } catch (error) {
      console.error('Error adding to shopping list:', error)
      alert('Failed to add to shopping list')
    }
  }

  async submitComment(event) {
    event.preventDefault()

    const content = this.commentInputTarget.value.trim()
    if (!content) {
      alert('Please enter a comment')
      return
    }

    try {
      const response = await fetch(`/api/v1/meal_plans/${this.mealPlanIdValue}/comments`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': this.csrfToken
        },
        body: JSON.stringify({ comment: { content } })
      })

      if (!response.ok) {
        const data = await response.json()
        throw new Error(data.errors?.[0] || 'Failed to post comment')
      }

      const comment = await response.json()
      
      // Add comment to list
      const emptyMsg = this.commentsListTarget.querySelector('p.text-muted')
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

    if (!confirm('Delete this comment?')) {
      return
    }

    try {
      const response = await fetch(`/api/v1/comments/${commentId}`, {
        method: 'DELETE',
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': this.csrfToken
        }
      })

      if (!response.ok) throw new Error('Failed to delete comment')

      // Remove from DOM
      const commentEl = this.commentsListTarget.querySelector(`[data-comment-id="${commentId}"]`)
      commentEl.remove()

      // Show empty message if no comments left
      if (this.commentsListTarget.children.length === 0) {
        this.commentsListTarget.innerHTML = '<p class="text-muted">No comments yet. Be the first to comment!</p>'
      }

    } catch (error) {
      console.error('Error deleting comment:', error)
      alert('Failed to delete comment')
    }
  }

  formatDate(date) {
    return date.toLocaleDateString('en-US', { 
      weekday: 'long', 
      year: 'numeric', 
      month: 'long', 
      day: 'numeric' 
    })
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

  get currentUserId() {
    return parseInt(document.body.dataset.currentUserId)
  }
}