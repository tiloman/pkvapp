require "application_system_test_case"

class OperationsTest < ApplicationSystemTestCase
  setup do
    @operation = operations(:one)
  end

  test "visiting the index" do
    visit operations_url
    assert_selector "h1", text: "Operations"
  end

  test "creating a Operation" do
    visit operations_url
    click_on "New Operation"

    fill_in "Assistance paid", with: @operation.assistance_paid
    fill_in "Assistance submitted", with: @operation.assistance_submitted
    fill_in "Billing date", with: @operation.billing_date
    fill_in "Description", with: @operation.description
    fill_in "Insurance paid", with: @operation.insurance_paid
    fill_in "Insurance submitted", with: @operation.insurance_submitted
    fill_in "Title", with: @operation.title
    fill_in "Value", with: @operation.value
    click_on "Create Operation"

    assert_text "Operation was successfully created"
    click_on "Back"
  end

  test "updating a Operation" do
    visit operations_url
    click_on "Edit", match: :first

    fill_in "Assistance paid", with: @operation.assistance_paid
    fill_in "Assistance submitted", with: @operation.assistance_submitted
    fill_in "Billing date", with: @operation.billing_date
    fill_in "Description", with: @operation.description
    fill_in "Insurance paid", with: @operation.insurance_paid
    fill_in "Insurance submitted", with: @operation.insurance_submitted
    fill_in "Title", with: @operation.title
    fill_in "Value", with: @operation.value
    click_on "Update Operation"

    assert_text "Operation was successfully updated"
    click_on "Back"
  end

  test "destroying a Operation" do
    visit operations_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Operation was successfully destroyed"
  end
end
