// app/javascript/controllers/api_controller.js

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.initializeToken()
  }

  async initializeToken() {
    if (!this.hasValidToken()) {
      await this.fetchTokenFromSession()
    }
  }

  hasValidToken() {
    const token = localStorage.getItem('access_token')
    const expiresAt = localStorage.getItem('token_expires_at')
    
    if (!token || !expiresAt) {
      return false
    }

    // Check if token is expired (with 5 minute buffer)
    return Date.now() < (parseInt(expiresAt) - 300000)
  }

  async fetchTokenFromSession() {
    try {
      const response = await fetch('/api/tokens', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.csrfToken
        },
        credentials: 'same-origin'
      })

      if (response.ok) {
        const data = await response.json()
        this.storeToken(data)
        return data.access_token
      } else {
        console.error('Failed to fetch token:', response.statusText)
  
  // CHANGE THIS: Instead of redirecting immediately, 
  // just return null and let the specific page handle the error.
  // Only redirect if you are SURE the user needs to see the login screen.
        return null
        // console.error('Failed to fetch token:', response.statusText)
        // if (response.status === 401) {
        //   window.location.href = '/users/sign_in'
        // }
        // return null
      }
    } catch (error) {
      console.error('Error fetching token:', error)
      return null
    }
  }

  storeToken(data) {
    localStorage.setItem('access_token', data.access_token)
    if (data.refresh_token) {
      localStorage.setItem('refresh_token', data.refresh_token)
    }
    localStorage.setItem('token_expires_at', Date.now() + (data.expires_in * 1000))
  }

  async getAccessToken() {
    if (!this.hasValidToken()) {
      await this.fetchTokenFromSession()
    }
    return localStorage.getItem('access_token')
  }

  async apiRequest(url, options = {}) {
    const token = await this.getAccessToken()

    if (!token) {
      throw new Error('No access token available')
    }

    const headers = {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
      ...options.headers
    }

    const response = await fetch(url, {
      ...options,
      headers
    })

    // If unauthorized, try refreshing token once
    if (response.status === 401) {
      localStorage.removeItem('access_token')
      await this.fetchTokenFromSession()
      const newToken = await this.getAccessToken()
      
      if (newToken) {
        headers.Authorization = `Bearer ${newToken}`
        return fetch(url, { ...options, headers })
      } else {
        window.location.href = '/users/sign_in'
      }
    }

    return response
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ''
  }

  // Helper methods
  async get(url, options = {}) {
    return this.apiRequest(url, { method: 'GET', ...options })
  }

  async post(url, data, options = {}) {
    return this.apiRequest(url, {
      method: 'POST',
      body: JSON.stringify(data),
      ...options
    })
  }

  async patch(url, data, options = {}) {
    return this.apiRequest(url, {
      method: 'PATCH',
      body: JSON.stringify(data),
      ...options
    })
  }

  async delete(url, options = {}) {
    return this.apiRequest(url, { method: 'DELETE', ...options })
  }

  clearTokens() {
    localStorage.removeItem('access_token')
    localStorage.removeItem('refresh_token')
    localStorage.removeItem('token_expires_at')
  }
}