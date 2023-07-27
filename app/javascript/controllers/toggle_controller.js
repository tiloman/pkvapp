import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox"]

  connect() {
    this.element.addEventListener("click", this.toggle.bind(this))
  }

  toggle(event) {
    // event.preventDefault()
    //TODO: set status of checkbox after success

    const value     = this.checkboxTarget.checked
    const url       = this.element.dataset.url
    const attribute = this.checkboxTarget.name

    var obj = {};
    obj[attribute] = value;

    fetch(url, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfToken(),
      },
      body: JSON.stringify(obj),
    })
  }

  csrfToken() {
    return document.querySelector('meta[name="csrf-token"]').getAttribute("content")
  }
}
