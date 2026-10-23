import {Controller} from "@hotwired/stimulus"

// Reloads the page until the server-side state changes (e.g. an AI run finishing).
export default class extends Controller {
  static values = {interval: {type: Number, default: 2000}}

  connect() {
    this.timer = setTimeout(() => window.location.reload(), this.intervalValue)
  }

  disconnect() {
    clearTimeout(this.timer)
  }
}
