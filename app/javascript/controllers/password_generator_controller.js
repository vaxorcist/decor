// decor/app/javascript/controllers/password_generator_controller.js - version 1.0
// Stimulus controller for generating secure passwords
// Generates 16-character passwords using cryptographically secure random values
// Character set: A-Z, a-z, 2-9 (excludes 0,1 for clarity), !@#$%^&*
// Automatically fills both password and confirmation fields

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // Define targets - password and confirmation input fields
  static targets = ["password", "confirmation"]

  // Character sets for password generation
  // Using unambiguous characters (no 0, 1, O, I, l) for better readability
  uppercase = "ABCDEFGHJKLMNPQRSTUVWXYZ" // Excludes O, I
  lowercase = "abcdefghjkmnpqrstuvwxyz"  // Excludes l, i
  numbers = "23456789"                   // Excludes 0, 1
  special = "!@#$%^&*"

  generate() {
    // Generate a 16-character secure password
    const password = this.generateSecurePassword(16)
    
    // Fill both password and confirmation fields
    this.passwordTarget.value = password
    this.confirmationTarget.value = password
    
    // Change password field to text type temporarily so user can see generated password
    // This is important for usability - user needs to save the password
    this.passwordTarget.type = "text"
    this.confirmationTarget.type = "text"
    
    // Show visual feedback that password was generated
    this.flashGenerated()
  }

  generateSecurePassword(length) {
    // Combine all character sets
    const allChars = this.uppercase + this.lowercase + this.numbers + this.special
    
    // Ensure password contains at least one character from each set
    // This provides good entropy distribution
    let password = [
      this.getRandomChar(this.uppercase),
      this.getRandomChar(this.lowercase),
      this.getRandomChar(this.numbers),
      this.getRandomChar(this.special)
    ]
    
    // Fill remaining characters randomly from all character sets
    for (let i = password.length; i < length; i++) {
      password.push(this.getRandomChar(allChars))
    }
    
    // Shuffle the password array to randomize position of guaranteed characters
    // Fisher-Yates shuffle algorithm for cryptographically secure shuffling
    for (let i = password.length - 1; i > 0; i--) {
      const j = Math.floor(this.getSecureRandom() * (i + 1));
      [password[i], password[j]] = [password[j], password[i]]
    }
    
    return password.join("")
  }

  getRandomChar(charset) {
    // Use cryptographically secure random number generation
    const randomIndex = Math.floor(this.getSecureRandom() * charset.length)
    return charset[randomIndex]
  }

  getSecureRandom() {
    // Use Web Crypto API for cryptographically secure random numbers
    // Falls back to Math.random() if crypto not available (shouldn't happen in modern browsers)
    if (window.crypto && window.crypto.getRandomValues) {
      const array = new Uint32Array(1)
      window.crypto.getRandomValues(array)
      return array[0] / (0xFFFFFFFF + 1)
    }
    return Math.random()
  }

  flashGenerated() {
    // Visual feedback: briefly highlight the button
    const button = this.element.querySelector('[data-action="password-generator#generate"]')
    if (button) {
      const originalText = button.textContent
      button.textContent = "✓ Password Generated"
      button.classList.add("text-green-600")
      
      setTimeout(() => {
        button.textContent = originalText
        button.classList.remove("text-green-600")
      }, 2000)
    }
  }
}
