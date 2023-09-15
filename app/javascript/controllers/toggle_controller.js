import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["unchecked", "checked", "waiting"]
  static values = {
    checked: Boolean,
    url: String,
    attribute: String
  }

  connect() {
  }

  toggle(event) {
    const value = !this.checkedValue
    const url = this.urlValue
    const attribute = this.attributeValue

    var obj = {};
    obj[attribute] = value;

    this.waitingTarget.classList.remove('d-none')
    this.checkedTarget.classList.add('d-none')
    this.uncheckedTarget.classList.add('d-none')

    fetch(url, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfToken(),
      },
      body: JSON.stringify(obj),
    }).then(response => {
      this.waitingTarget.classList.add('d-none')
      console.log(response)
      if (response.ok) {
        this.checkedTarget.classList.toggle('d-none', this.checkedValue)
        this.uncheckedTarget.classList.toggle('d-none', !this.checkedValue)
        this.checkedValue = !this.checkedValue
      } else {
        this.checkedTarget.classList.toggle('d-none', !this.checkedValue)
        this.uncheckedTarget.classList.toggle('d-none', this.checkedValue)
        console.log('FEEEHLER')
      }
    })
  }


  csrfToken() {
    return document.querySelector('meta[name="csrf-token"]').getAttribute("content")
  }
}
