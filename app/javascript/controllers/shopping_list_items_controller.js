// app/javascript/controllers/shopping_list_items_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "tableBody", "emptyState", "totalItems", "purchasedCount", 
    "remainingCount", "errors", "successMessage",
    // Tab 1: Select Item
    "itemSelect", "itemQuantity",
    // Tab 2: Select Ingredient
    "ingredientSelect", "ingredientQuantity",
    // Tab 3: Manual Entry
    "manualType", "manualName", "manualQuantity"
  ]
  static values = {
    currentTab: { type: String, default: "select_item" }
  }

  connect() {
    console.log("Shopping list controller connected")
    this.loadItems()
  }

  async loadItems() {
    try {
      const response = await fetch('/api/v1/shopping_list_items', {
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': this.csrfToken
        }
      })

      if (!response.ok) throw new Error('Failed to load shopping list')

      const items = await response.json()
      console.log('Shopping list items loaded:', items)
      this.renderItems(items)
    } catch (error) {
      console.error('Error loading shopping list:', error)
      this.showError('Failed to load shopping list')
    }
  }

  renderItems(items) {
    if (items.length === 0) {
      this.showEmptyState()
      return
    }

    this.hideEmptyState()
    
    // Group items
    const purchased = items.filter(item => item.is_purchased).length
    const remaining = items.filter(item => !item.is_purchased).length

    // Update counts
    if (this.hasTotalItemsTarget) {
      this.totalItemsTarget.textContent = items.length
    }
    if (this.hasPurchasedCountTarget) {
      this.purchasedCountTarget.textContent = purchased
    }
    if (this.hasRemainingCountTarget) {
      this.remainingCountTarget.textContent = remaining
    }

    // Render table rows
    this.tableBodyTarget.innerHTML = items.map(item => this.renderItemRow(item)).join('')
  }

  renderItemRow(item) {
    
    const rowClass = item.is_purchased ? 'table-secondary' : ''
    const strikethrough = item.is_purchased ? '<s>' : ''
    const strikethroughClose = item.is_purchased ? '</s>' : ''
    
    // Get item name based on purchasable type
    let itemName = 'Unknown Item'
    let badgeClass = 'secondary'
    
    if (item.purchasable) {
      if (item.purchasable_type === 'Recipe') {
        itemName = item.purchasable.title || 'Unknown Recipe'
        badgeClass = 'info'
      } else if (item.purchasable_type === 'Item') {
        itemName = item.purchasable.item_name || 'Unknown Item'
        badgeClass = 'primary'
      } else if (item.purchasable_type === 'Ingredient') {
        itemName = item.purchasable.name || 'Unknown Ingredient'
        badgeClass = 'secondary'
      }
    }

    const inPaymentBadge = item.payment_id ? '<span class="badge bg-success ms-2">In Payments</span>' : ''
    
   const paymentButton = item.has_payment
    ? '<span class="text-muted small">Already in payments</span>'
    : `<button type="button" 
           class="btn btn-sm btn-success"
           data-action="click->shopping-list-items#addToPayment"
           data-item-id="${item.id}">
           Add to Payment
         </button>`

    return `
      <tr class="${rowClass}" data-item-id="${item.id}">
        <td>
          <input type="checkbox" 
                 class="form-check-input"
                 ${item.is_purchased ? 'checked' : ''}
                 data-action="change->shopping-list-items#togglePurchased"
                 data-item-id="${item.id}">
        </td>
        <td>
          ${strikethrough}${itemName}${strikethroughClose}
          ${inPaymentBadge}
        </td>
        <td>
          <div class="d-flex align-items-center">
            <input type="text" 
                   class="form-control form-control-sm me-2"
                   style="width: 120px;"
                   value="${item.quantity}"
                   data-item-id="${item.id}"
                   data-shopping-list-items-target="quantityInput">
            <button type="button" 
                    class="btn btn-sm btn-outline-primary"
                    data-action="click->shopping-list-items#updateQuantity"
                    data-item-id="${item.id}">
              Update
            </button>
          </div>
        </td>
        <td>
          <span class="badge bg-${badgeClass}">
            ${item.purchasable_type}
          </span>
        </td>
        <td>
          <div class="d-flex gap-2">
            ${paymentButton}
            <button type="button" 
                    class="btn btn-sm btn-outline-danger"
                    data-action="click->shopping-list-items#removeItem"
                    data-item-id="${item.id}">
              Remove
            </button>
          </div>
        </td>
      </tr>
    `
  }

  // Tab: Select Item
  async addExistingItem(event) {
    event.preventDefault()
    
    const itemId = this.itemSelectTarget.value
    const quantity = this.itemQuantityTarget.value

    if (!itemId) {
      this.showError(['Please select an item'])
      return
    }

    await this.createItem({
      item_type: 'existing_item',
      item_id: itemId,
      quantity: quantity
    })
  }

  // Tab: Select Ingredient
  async addExistingIngredient(event) {
    event.preventDefault()
    
    const ingredientId = this.ingredientSelectTarget.value
    const quantity = this.ingredientQuantityTarget.value

    if (!ingredientId) {
      this.showError(['Please select an ingredient'])
      return
    }

    await this.createItem({
      item_type: 'existing_ingredient',
      ingredient_id: ingredientId,
      quantity: quantity
    })
  }

  // Tab: Manual Entry
  async addManualItem(event) {
    event.preventDefault()
    
    const itemType = this.manualTypeTarget.value
    const name = this.manualNameTarget.value.trim()
    const quantity = this.manualQuantityTarget.value

    if (!name) {
      this.showError(['Please enter a name'])
      return
    }

    await this.createItem({
      item_type: itemType,
      manual_name: name,
      quantity: quantity
    })
  }

  async createItem(itemData) {
    try {
      const response = await fetch('/api/v1/shopping_list_items', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': this.csrfToken
        },
        body: JSON.stringify({ shopping_list_item: itemData })
      })

      const data = await response.json()

      if (!response.ok) {
        this.showError([data.error || 'Failed to add item'])
        return
      }

      this.showSuccess('Item added to shopping list!')
      this.clearForm()
      this.loadItems()

    } catch (error) {
      console.error('Error adding item:', error)
      this.showError(['Failed to add item. Please try again.'])
    }
  }

  async togglePurchased(event) {
    const itemId = event.target.dataset.itemId
    const isPurchased = event.target.checked

    try {
      const response = await fetch(`/api/v1/shopping_list_items/${itemId}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': this.csrfToken
        },
        body: JSON.stringify({ 
          shopping_list_item: { is_purchased: isPurchased } 
        })
      })

      if (!response.ok) throw new Error('Failed to update item')

      this.loadItems()

    } catch (error) {
      console.error('Error toggling purchased:', error)
      event.target.checked = !isPurchased // Revert checkbox
      this.showError(['Failed to update item'])
    }
  }

  async updateQuantity(event) {
    const itemId = event.target.dataset.itemId
    const row = event.target.closest('tr')
    const input = row.querySelector(`input[data-item-id="${itemId}"]`)
    const newQuantity = input.value.trim()

    if (!newQuantity) {
      this.showError(['Please enter a quantity'])
      return
    }

    try {
      const response = await fetch(`/api/v1/shopping_list_items/${itemId}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': this.csrfToken
        },
        body: JSON.stringify({ 
          shopping_list_item: { quantity: newQuantity } 
        })
      })

      if (!response.ok) throw new Error('Failed to update quantity')

      this.showSuccess('Quantity updated!')
      this.loadItems()

    } catch (error) {
      console.error('Error updating quantity:', error)
      this.showError(['Failed to update quantity'])
    }
  }

  async removeItem(event) {
    const itemId = event.target.dataset.itemId

    if (!confirm('Remove this item from your shopping list?')) {
      return
    }

    try {
      const response = await fetch(`/api/v1/shopping_list_items/${itemId}`, {
        method: 'DELETE',
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': this.csrfToken
        }
      })

      if (!response.ok) throw new Error('Failed to remove item')

      this.showSuccess('Item removed!')
      this.loadItems()

    } catch (error) {
      console.error('Error removing item:', error)
      this.showError(['Failed to remove item'])
    }
  }

  async clearPurchased() {
    if (!confirm('Remove all purchased items from the list?')) {
      return
    }

    try {
      const response = await fetch('/api/v1/shopping_list_items/clear_purchased', {
        method: 'DELETE',
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': this.csrfToken
        }
      })

      if (!response.ok) throw new Error('Failed to clear purchased items')

      this.showSuccess('Purchased items cleared!')
      this.loadItems()

    } catch (error) {
      console.error('Error clearing purchased items:', error)
      this.showError(['Failed to clear purchased items'])
    }
  }

  async addToPayment(event) {
    const itemId = event.target.dataset.itemId

    if (!confirm('Add this item to payments?')) {
      return
    }

    try {
      const response = await fetch('/api/v1/payments', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': this.csrfToken
        },
        body: JSON.stringify({ shopping_list_item_id: itemId })
      })

      if (!response.ok) throw new Error('Failed to add to payments')

      this.showSuccess('Item added to payments!')
      this.loadItems()

    } catch (error) {
      console.error('Error adding to payments:', error)
      this.showError(['Failed to add to payments'])
    }
  }

  switchTab(event) {
    event.preventDefault()
    const tab = event.target.dataset.tab
    this.currentTabValue = tab
    
    // Hide all tabs
    document.getElementById('select-item-tab').style.display = 'none'
    document.getElementById('select-ingredient-tab').style.display = 'none'
    document.getElementById('manual-tab').style.display = 'none'
    
    // Show selected tab
    document.getElementById(`${tab.replace('_', '-')}-tab`).style.display = 'block'
    
    // Update active class on nav links
    document.querySelectorAll('.nav-link').forEach(link => {
      link.classList.remove('active')
    })
    event.target.classList.add('active')
    
    // Update URL without page reload
    const url = new URL(window.location)
    url.searchParams.set('add_tab', tab)
    window.history.pushState({}, '', url)
  }

  clearForm() {
    // Clear all form inputs based on current tab
    if (this.hasItemSelectTarget) this.itemSelectTarget.value = ''
    if (this.hasItemQuantityTarget) this.itemQuantityTarget.value = '1'
    if (this.hasIngredientSelectTarget) this.ingredientSelectTarget.value = ''
    if (this.hasIngredientQuantityTarget) this.ingredientQuantityTarget.value = '1'
    if (this.hasManualNameTarget) this.manualNameTarget.value = ''
    if (this.hasManualQuantityTarget) this.manualQuantityTarget.value = '1'
  }

  showEmptyState() {
    if (this.hasTableBodyTarget) {
      this.tableBodyTarget.innerHTML = ''
    }
    if (this.hasEmptyStateTarget) {
      this.emptyStateTarget.style.display = 'block'
    }
  }

  hideEmptyState() {
    if (this.hasEmptyStateTarget) {
      this.emptyStateTarget.style.display = 'none'
    }
  }

  showError(messages) {
    if (!this.hasErrorsTarget) return

    const errorHtml = `
      <div class="alert alert-danger alert-dismissible fade show" role="alert">
        <ul class="mb-0">
          ${messages.map(msg => `<li>${msg}</li>`).join('')}
        </ul>
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
      </div>
    `
    this.errorsTarget.innerHTML = errorHtml
    this.errorsTarget.scrollIntoView({ behavior: 'smooth', block: 'nearest' })

    setTimeout(() => this.clearMessages(), 5000)
  }

  showSuccess(message) {
    if (!this.hasSuccessMessageTarget) return

    const successHtml = `
      <div class="alert alert-success alert-dismissible fade show" role="alert">
        ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
      </div>
    `
    this.successMessageTarget.innerHTML = successHtml

    setTimeout(() => this.clearMessages(), 3000)
  }

  clearMessages() {
    if (this.hasErrorsTarget) this.errorsTarget.innerHTML = ''
    if (this.hasSuccessMessageTarget) this.successMessageTarget.innerHTML = ''
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ''
  }
}