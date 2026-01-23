// app/javascript/controllers/payments_controller.js

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "pendingTableBody", "completedTableBody", "deletedTableBody",
    "totalCount", "pendingCount", "completedCount",
    "pendingEmptyState", "completedEmptyState", "deletedEmptyState",
    "messages"
  ]

  connect() {
    this.loadPayments()
  }

  async loadPayments() {
    try {
      const apiController = this.getApiController()
      const response = await apiController.get('/api/v1/payments')
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      
      const data = await response.json()
      this.renderPayments(data)
    } catch (error) {
      console.error("Error loading payments:", error)
      this.showMessage("Error loading payments", "danger")
    }
  }

  renderPayments(data) {
    const { pending, completed, all_payments } = data

    this.totalCountTarget.textContent = all_payments.length
    this.pendingCountTarget.textContent = pending.length
    this.completedCountTarget.textContent = completed.length

    if (pending.length > 0) {
      this.pendingEmptyStateTarget.style.display = "none"
      this.pendingTableBodyTarget.innerHTML = pending.map(p => this.rowTemplate(p)).join('')
    } else {
      this.pendingTableBodyTarget.innerHTML = ""
      this.pendingEmptyStateTarget.style.display = "block"
    }

    if (completed.length > 0) {
      this.completedEmptyStateTarget.style.display = "none"
      this.completedTableBodyTarget.innerHTML = completed.map(p => this.rowTemplate(p)).join('')
    } else {
      this.completedTableBodyTarget.innerHTML = ""
      this.completedEmptyStateTarget.style.display = "block"
    }
  }

  rowTemplate(payment) {
    const isPending = payment.payment_status === 'pending'
    const date = new Date(isPending ? payment.created_at : payment.updated_at).toLocaleDateString()
    
    const itemName = payment.item_name || "Unknown Item"
    const quantity = payment.shopping_list_item?.quantity || "1"
    const type = payment.shopping_list_item?.purchasable_type || "Item"

    return `
      <tr class="${!isPending ? 'completed-row' : ''}" data-payment-id="${payment.id}">
        <td>
          <span class="payment-item-name">${itemName}</span>
          ${!isPending ? '<span class="payment-badge badge-paid">✓ Paid</span>' : ''}
        </td>
        <td>${quantity}</td>
        <td><span class="payment-badge badge-${type.toLowerCase()}">${type}</span></td>
        <td>${date}</td>
        <td>
          ${isPending ? 
            `<button class="payment-btn payment-btn-success" data-action="click->payments#updateStatus" data-id="${payment.id}" data-status="completed">✓ Mark as Paid</button>` :
            `<button class="payment-btn payment-btn-warning" data-action="click->payments#updateStatus" data-id="${payment.id}" data-status="pending">↺ Undo</button>`
          }
          <button class="payment-btn payment-btn-danger" data-action="click->payments#destroy" data-id="${payment.id}">Remove</button>
        </td>
      </tr>
    `
  }

  async updateStatus(event) {
    const { id, status } = event.target.dataset
    
    try {
      const apiController = this.getApiController()
      const response = await apiController.patch(
        `/api/v1/payments/${id}`, 
        { payment: { payment_status: status } }
      )
      
      if (response.ok) {
        this.showMessage("✓ Payment status updated", "success")
        this.loadPayments()
      } else {
        const errorData = await response.json()
        throw new Error(errorData.error || 'Failed to update status')
      }
    } catch (error) {
      console.error("Error updating payment:", error)
      this.showMessage(`Failed to update payment status: ${error.message}`, "danger")
    }
  }

  async destroy(event) {
    const { id } = event.target.dataset
    const row = event.target.closest('tr')
    
    if (!confirm("Remove this from payments? You can restore it later.")) return
    
    try {
      const apiController = this.getApiController()
      const response = await apiController.delete(`/api/v1/payments/${id}`)
      
      if (response.ok) {
        this.showMessageWithUndo("✓ Payment removed", "success", id)
        
        row.style.transition = 'opacity 0.3s'
        row.style.opacity = '0'
        
        setTimeout(() => {
          this.loadPayments()
        }, 300)
      } else {
        const errorData = await response.json()
        throw new Error(errorData.error || 'Failed to delete payment')
      }
    } catch (error) {
      console.error("Error deleting payment:", error)
      this.showMessage(`Failed to remove payment: ${error.message}`, "danger")
    }
  }

  // FIXED RESTORE METHOD
  async restore(event) {
    const { id } = event.target.dataset
    const button = event.target
    
    // Disable button during request
    button.disabled = true
    button.textContent = "Restoring..."
    
    try {
      const apiController = this.getApiController()
      const response = await apiController.patch(`/api/v1/payments/${id}/restore`, {})
      
      if (response.ok) {
        const data = await response.json()
        this.showMessage("✓ Payment restored successfully", "success")
        
        // Reload both main payments and deleted section
        this.loadPayments()
        
        // If deleted section is visible, reload it too
        const deletedSection = document.getElementById('deletedSection')
        if (deletedSection && deletedSection.style.display !== 'none') {
          this.loadDeleted()
        }
      } else {
        const errorData = await response.json()
        throw new Error(errorData.error || 'Failed to restore payment')
      }
    } catch (error) {
      console.error("Error restoring payment:", error)
      this.showMessage(`Failed to restore payment: ${error.message}`, "danger")
      button.disabled = false
      button.textContent = "↺ Restore"
    }
  }

  async clearCompleted() {
    if (!confirm("Remove all completed payments? You can restore them later if needed.")) return
    
    try {
      const apiController = this.getApiController()
      const response = await apiController.delete('/api/v1/payments/clear_completed')
      
      if (response.ok) {
        const data = await response.json()
        this.showMessage(`✓ ${data.count} completed payments cleared`, "success")
        this.loadPayments()
      } else {
        const errorData = await response.json()
        throw new Error(errorData.error || 'Failed to clear completed payments')
      }
    } catch (error) {
      console.error("Error clearing payments:", error)
      this.showMessage(`Failed to clear completed payments: ${error.message}`, "danger")
    }
  }

  async loadDeleted() {
    const deletedSection = document.getElementById('deletedSection')
    
    if (deletedSection.style.display === 'none') {
      try {
        const apiController = this.getApiController()
        const response = await apiController.get('/api/v1/payments/deleted')
        
        if (response.ok) {
          const data = await response.json()
          this.renderDeleted(data.deleted_payments)
          deletedSection.style.display = 'block'
        } else {
          throw new Error('Failed to load deleted payments')
        }
      } catch (error) {
        console.error("Error loading deleted payments:", error)
        this.showMessage("Error loading deleted payments", "danger")
      }
    } else {
      deletedSection.style.display = 'none'
    }
  }

  renderDeleted(payments) {
    if (this.hasDeletedTableBodyTarget) {
      if (payments.length > 0) {
        this.deletedEmptyStateTarget.style.display = "none"
        this.deletedTableBodyTarget.innerHTML = payments.map(p => this.deletedRowTemplate(p)).join('')
      } else {
        this.deletedTableBodyTarget.innerHTML = ""
        this.deletedEmptyStateTarget.style.display = "block"
      }
    }
  }

  // deletedRowTemplate(payment) {
  //   const date = payment.deleted_at ? new Date(payment.deleted_at).toLocaleDateString() : 'N/A'
  //   const itemName = payment.item_name || "Unknown Item"
  //   const quantity = payment.shopping_list_item?.quantity || "1"
  //   const type = payment.shopping_list_item?.purchasable_type || "Item"

  //   return `
  //     <tr class="deleted-row" style="opacity: 0.7;">
  //       <td>
  //         <span class="payment-item-name">${itemName}</span>
  //         <span class="payment-badge badge-deleted" style="background: #dc3545; color: white;">Deleted</span>
  //       </td>
  //       <td>${quantity}</td>
  //       <td><span class="payment-badge badge-${type.toLowerCase()}">${type}</span></td>
  //       <td>${date}</td>
  //       <td>
  //         <button class="payment-btn payment-btn-success" 
  //                 data-action="click->payments#restore" 
  //                 data-id="${payment.id}">
  //           ↺ Restore
  //         </button>
  //       </td>
  //     </tr>
  //   `
  // }
  // Improved permanentDestroy method with better state management
async permanentDestroy(event) {
  const { id } = event.target.dataset
  const button = event.target
  const row = event.target.closest('tr')
  
  if (!confirm("⚠️ Permanently delete this item? This action CANNOT be undone!")) {
    return
  }

  // Disable button and show loading state
  button.disabled = true
  const originalText = button.innerHTML
  button.innerHTML = '⌛ Deleting...'
  
  try {
    const apiController = this.getApiController()
    const response = await apiController.delete(`/api/v1/payments/${id}/permanent`)
    
    if (response.ok) {
      this.showMessage("✓ Item permanently deleted", "success")
      
      // Visual feedback: Fade out the row
      row.style.transition = 'opacity 0.3s, transform 0.3s'
      row.style.opacity = '0'
      row.style.transform = 'translateX(-20px)'
      
      setTimeout(() => {
        row.remove()
        
        // Refresh the deleted section to update counts/empty states
        this.refreshDeletedData()
        
        // Also reload main payments to update overall counts
        this.loadPayments()
      }, 300)
      
    } else {
      const errorData = await response.json()
      throw new Error(errorData.error || 'Failed to permanently delete')
    }
    
  } catch (error) {
    console.error("Error purging payment:", error)
    this.showMessage(`❌ Failed to delete: ${error.message}`, "danger")
    
    // Re-enable button on error
    button.disabled = false
    button.innerHTML = originalText
  }
}

// Improved refreshDeletedData with empty state handling
async refreshDeletedData() {
  try {
    const apiController = this.getApiController()
    const response = await apiController.get('/api/v1/payments/deleted')
    
    if (response.ok) {
      const data = await response.json()
      this.renderDeleted(data.deleted_payments)
      
      // Auto-hide section if empty
      if (data.deleted_payments.length === 0) {
        const deletedSection = document.getElementById('deletedSection')
        if (deletedSection) {
          deletedSection.style.display = 'none'
        }
      }
    }
  } catch (error) {
    console.error("Silent refresh failed:", error)
  }
}

// Enhanced deletedRowTemplate with better button styling
deletedRowTemplate(payment) {
  const date = payment.deleted_at ? new Date(payment.deleted_at).toLocaleDateString() : 'N/A'
  const itemName = payment.item_name || "Unknown Item"
  const quantity = payment.shopping_list_item?.quantity || "1"
  const type = payment.shopping_list_item?.purchasable_type || "Item"

  return `
    <tr class="deleted-row" data-payment-id="${payment.id}" style="opacity: 0.7;">
      <td>
        <span class="payment-item-name">${itemName}</span>
        <span class="payment-badge badge-deleted" 
              style="background: #dc3545; color: white; padding: 2px 8px; border-radius: 4px; font-size: 0.75rem; margin-left: 8px;">
          🗑️ Deleted
        </span>
      </td>
      <td>${quantity}</td>
      <td><span class="payment-badge badge-${type.toLowerCase()}">${type}</span></td>
      <td>${date}</td>
      <td>
        <div class="d-flex gap-2">
          <button class="payment-btn payment-btn-success" 
                  data-action="click->payments#restore" 
                  data-id="${payment.id}"
                  title="Restore this payment">
            ↺ Restore
          </button>
          <button class="payment-btn payment-btn-danger" 
                  data-action="click->payments#permanentDestroy" 
                  data-id="${payment.id}"
                  title="Permanently delete - cannot be undone"
                  style="background-color: #6c757d; border-color: #5a6268;">
            🗑️ Purge
          </button>
        </div>
      </td>
    </tr>
  `
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

  showMessageWithUndo(text, type, paymentId) {
    this.messagesTarget.innerHTML = `
      <div class="payment-alert payment-alert-${type}">
        ${text}
        <button class="payment-btn payment-btn-sm payment-btn-secondary ml-2" 
                data-action="click->payments#restore" 
                data-id="${paymentId}"
                style="font-size: 0.875rem; padding: 0.25rem 0.5rem;">
          ↺ Undo
        </button>
      </div>
    `
    
    setTimeout(() => {
      this.messagesTarget.innerHTML = ""
    }, 5000)
  }

  showMessage(text, type) {
    this.messagesTarget.innerHTML = `<div class="payment-alert payment-alert-${type}">${text}</div>`
    setTimeout(() => this.messagesTarget.innerHTML = "", 3000)
  }
}