import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "pendingTableBody", "completedTableBody", 
    "totalCount", "pendingCount", "completedCount",
    "pendingEmptyState", "completedEmptyState", "messages"
  ]

  connect() {
    this.loadPayments()
  }

  async loadPayments() {
    try {
      const response = await fetch('/api/v1/payments', {
        headers: { 'Accept': 'application/json' }
      })
      const data = await response.json()
      this.renderPayments(data)
    } catch (error) {
      this.showMessage("Error loading payments", "danger")
    }
  }

  renderPayments(data) {
    const { pending, completed, all_payments } = data

    // Update Counts
    this.totalCountTarget.textContent = all_payments.length
    this.pendingCountTarget.textContent = pending.length
    this.completedCountTarget.textContent = completed.length

    // Render Pending
    if (pending.length > 0) {
      this.pendingEmptyStateTarget.style.display = "none"
      this.pendingTableBodyTarget.innerHTML = pending.map(p => this.rowTemplate(p)).join('')
    } else {
      this.pendingTableBodyTarget.innerHTML = ""
      this.pendingEmptyStateTarget.style.display = "block"
    }

    // Render Completed
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
    
    // Safety check for associated data
    const itemName = payment.item_name || "Unknown Item"
    const quantity = payment.shopping_list_item?.quantity || "1"
    const type = payment.shopping_list_item?.purchasable_type || "Item"

    return `
      <tr class="${!isPending ? 'completed-row' : ''}">
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
    await this.apiCall(`/api/v1/payments/${id}`, 'PATCH', { payment: { payment_status: status } })
    this.loadPayments()
  }

  async destroy(event) {
    if (!confirm("Remove this from payments?")) return
    const { id } = event.target.dataset
    await this.apiCall(`/api/v1/payments/${id}`, 'DELETE')
    this.loadPayments()
  }

  async clearCompleted() {
    if (!confirm("Remove all completed payments?")) return
    await this.apiCall('/api/v1/payments/clear_completed', 'DELETE')
    this.loadPayments()
  }

  // Helper for API calls
  async apiCall(url, method, body = null) {
    const options = {
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      }
    }
    if (body) options.body = JSON.stringify(body)
    const response = await fetch(url, options)
    return response
  }

  showMessage(text, type) {
    this.messagesTarget.innerHTML = `<div class="payment-alert payment-alert-${type}">${text}</div>`
    setTimeout(() => this.messagesTarget.innerHTML = "", 3000)
  }
}