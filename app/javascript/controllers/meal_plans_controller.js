// app/javascript/controllers/meal_plans_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "categoryInput", "startDateInput", "submitBtn", "tableBody", "emptyState", "errors"]

  connect() {
    console.log("Meal plans controller connected")
    this.loadMealPlans()
  }

  async loadMealPlans() {
    try {
      const response = await fetch('/api/v1/meal_plans', {
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': this.csrfToken
        }
      })

      if (!response.ok) throw new Error('Failed to load meal plans')

      const mealPlans = await response.json()
      this.renderMealPlans(mealPlans)
    } catch (error) {
      console.error('Error loading meal plans:', error)
      this.showError('Failed to load meal plans')
    }
  }

  renderMealPlans(mealPlans) {
    if (mealPlans.length === 0) {
      this.tableBodyTarget.innerHTML = ''
      if (this.hasEmptyStateTarget) {
        this.emptyStateTarget.style.display = 'block'
      }
      return
    }

    if (this.hasEmptyStateTarget) {
      this.emptyStateTarget.style.display = 'none'
    }

    this.tableBodyTarget.innerHTML = mealPlans.map(plan => this.mealPlanRowHTML(plan)).join('')
  }

  mealPlanRowHTML(plan) {
    // Format dates properly
    let startDate = 'Invalid Date'
    let endDate = 'Invalid Date'
    
    try {
      if (plan.start_date) {
        startDate = new Date(plan.start_date).toLocaleDateString('en-US', { 
          year: 'numeric', month: 'long', day: 'numeric' 
        })
      }
      if (plan.end_date) {
        endDate = new Date(plan.end_date).toLocaleDateString('en-US', { 
          year: 'numeric', month: 'long', day: 'numeric' 
        })
      }
    } catch (e) {
      console.error('Error formatting dates:', e, plan)
    }

    // Get user email
    const userEmail = plan.user?.email || 'Unknown'
    
    // Check if current user can delete
    const canDelete = plan.user_id === this.currentUserId

    const deleteBtn = canDelete ? `
      <button 
        type="button" 
        class="btn btn-sm btn-danger"
        data-action="click->meal-plans#delete"
        data-plan-id="${plan.id}">
        Delete
      </button>
    ` : ''

    return `
      <tr>
        <td>${plan.category || 'Untitled'}</td>
        <td>${startDate}</td>
        <td>${endDate}</td>
        <td>${userEmail}</td>
        <td>
          <a href="/meal_plans/${plan.id}" class="btn btn-sm btn-info">View</a>
          ${deleteBtn}
        </td>
      </tr>
    `
  }

  async submit(event) {
    event.preventDefault()
    
    this.clearErrors()
    this.submitBtnTarget.disabled = true
    this.submitBtnTarget.textContent = 'Creating...'

    const mealPlanData = {
      category: this.categoryInputTarget.value.trim(),
      start_date: this.startDateInputTarget.value
    }

    try {
      const response = await fetch('/api/v1/meal_plans', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': this.csrfToken
        },
        body: JSON.stringify({ meal_plan: mealPlanData })
      })

      const data = await response.json()

      if (!response.ok) {
        this.showError(data.errors || ['Failed to create meal plan'])
        return
      }

      // Success - redirect to the new meal plan
      window.location.href = `/meal_plans/${data.id}`

    } catch (error) {
      console.error('Error creating meal plan:', error)
      this.showError(['Failed to create meal plan. Please try again.'])
    } finally {
      this.submitBtnTarget.disabled = false
      this.submitBtnTarget.textContent = 'Create Meal Plan'
    }
  }

  async delete(event) {
    const planId = event.target.dataset.planId

    if (!confirm('Are you sure you want to delete this meal plan?')) {
      return
    }

    try {
      const response = await fetch(`/api/v1/meal_plans/${planId}`, {
        method: 'DELETE',
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': this.csrfToken
        }
      })

      if (!response.ok) {
        const data = await response.json()
        throw new Error(data.error || 'Failed to delete meal plan')
      }

      // Remove row from table
      const row = event.target.closest('tr')
      row.remove()

      // Check if table is empty
      if (this.tableBodyTarget.children.length === 0 && this.hasEmptyStateTarget) {
        this.emptyStateTarget.style.display = 'block'
      }

    } catch (error) {
      console.error('Error deleting meal plan:', error)
      alert(error.message || 'Failed to delete meal plan')
    }
  }

  showError(messages) {
    if (!this.hasErrorsTarget) return

    const errorHtml = `
      <div class="alert alert-danger">
        <h4>${messages.length} error(s) prohibited this meal plan from being saved:</h4>
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

  get currentUserId() {
    return parseInt(document.body.dataset.currentUserId)
  }
}