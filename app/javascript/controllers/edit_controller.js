import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["show", "form"]
  static values = {
    init: String,
    url: String
  }

  connect() {
    this.showTarget.addEventListener("click", () => this.editMode());
  }

  viewMode() {
    this.showTarget.classList.remove("d-none");
    this.formTarget.classList.add("d-none");
  }

  submitForm() {
    this.formTarget.querySelector("form").submit();
    this.viewMode();
  }

  editMode() {
    this.formTarget.classList.remove("d-none");
    this.showTarget.classList.add("d-none");
  }
}
