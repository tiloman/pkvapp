class OperationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_operation, only: %i[show edit update destroy]

  def index
    users_operations = Operation.where(person_id: [current_user.people])
    @people = current_user.people
    if params.dig('filterrific', 'view').present?
      @view = params[:filterrific][:view]
    elsif @view = params[:view]
    else
      @view = current_user.operations_view
    end

    @filterrific = initialize_filterrific(
      users_operations,
      params[:filterrific],
      select_options: {
        by_person: Operation.options_for_person_select(current_user),
        by_state: Operation.options_for_state_select(users_operations)
      },
    ) || return

    @operations = @filterrific.find.paginate(page: params[:page], per_page: 15)

    respond_to do |format|
      format.js {}
      format.html { render :index }
      format.json { respond_with_bip(@operations) }
    end
  end

  def show; end

  def new
    @operation = Operation.new
  end

  def edit; end

  def create
    @operation = Operation.new(operation_params)
    respond_to do |format|
      if @operation.save
        create_todoist_item
        format.html { redirect_to @operation, notice: 'Vorgang wurde angelegt.' }
        format.json { render :index, status: :created, location: @operation }
      else
        format.html { render :new }
        format.json { render json: @operation.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @operation.update(operation_params)
        update_todoist_item
        format.html { redirect_to @operation, notice: 'Operation was successfully updated.' }
        format.json { render :show, status: :ok, location: @operation }
        format.js {}
      else
        format.html { render :edit }
        format.json { render json: @operation.errors.full_messages, status: :unprocessable_entity }
      end
    end
  end

  def create_asset
    @bill = Image.new(params[:image_form])
    @bill.save
    render text: @bill.public_filename
  end

  def calendar
    @operations = Operation.unscoped.where(person_id: [current_user.people])
    respond_to do |format|
      format.html {}
      format.json {}
    end
  end

  def dashboard
    users_operations = Operation.unscoped.where(person_id: [current_user.people])
    @unpaid_operations = users_operations.unpaid_operations
    @paid_operations = users_operations.paid_operations

    @next_payment = users_operations.where('bill_deadline <= ?', Time.now).first
    @overdue_operations = users_operations.overdue
  end

  def destroy
    @operation.destroy
    respond_to do |format|
      format.html { redirect_to operations_url, notice: 'Operation was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  def set_operation
    @operation = Operation.find(params[:id])
  end

  def operation_params
    params.require(:operation).permit(:title, :value, :insurance_paid, :insurance_submitted, :insurance_payback, :assistance_paid, :assistance_submitted, :assistance_payback, :billing_date, :content, :person_id, :bill, :bill_deadline, :insurance_notice, :paid)
  end

  def todoist_client
    return unless current_user.todoist_integration

    @todoist_client ||= Todoist::Client.create_client_by_token(current_user.todoist_integration.token)
  end

  def create_todoist_item
    todoist_client
    @todoist_item = @todoist_client.sync_items.add(
      {
        content: "Rechnung fällig: #{@operation.title}",
        due: { string: (@operation.bill_deadline - current_user.remind_days_before.days).strftime("%d.%m.%Y") },
        description: todoist_description
      })
    @todoist_client.sync
    @operation.update(todoist_item_id: @todoist_item.id)
  end

  def update_todoist_item
    return unless @operation.todoist_item_id

    todoist_client
    done = @operation.paid ? 1 : 0
    @todoist_item = @todoist_client.sync_items.update(
      {
        id:           @operation.todoist_item_id,
        content:     "Rechnung fällig: #{@operation.title}",
        due:         { string: (@operation.bill_deadline - current_user.remind_days_before.days).strftime("%d.%m.%Y") },
        description: todoist_description,
        checked: done
      })
    @todoist_client.sync
  end

  def todoist_description
    "**Status: #{@operation.aasm_state}** \nPerson: #{@operation.person.name} \nBetrag: #{@operation.value} Euro\n\n[Bei Abile bearbeiten](#{operation_url(@operation)})"
  end
end
