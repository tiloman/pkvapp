class OperationsController < ApplicationController
  before_action :set_operation, only: [:show, :edit, :update, :destroy]


  def index
    users_operations = Operation.unscoped.where(person_id: [current_user.people])
    @people = current_user.people
    operations = users_operations

    # if params[:person]
    #   filtered_operations = operations.where(person_id: params[:person])
    # else
    #   filtered_operations = operations
    # end

    if params[:filter].present?
      filtered_operations = operations.where(paid: true) if params[:filter] == "bill_paid"
      filtered_operations = operations.where(paid: false) if params[:filter] == "bill_not_paid"
      filtered_operations = operations.where(insurance_submitted: true) if params[:filter] == "insurance_notice"
      filtered_operations = operations.where(insurance_submitted: false) if params[:filter] == "insurance_no_notice"
      filtered_operations = operations.where(insurance_paid: true) if params[:filter] == "insurance_paid"
      filtered_operations = operations.where(insurance_paid: false) if params[:filter] == "insurance_not_paid"
      filtered_operations = operations.where(assistance_submitted: true) if params[:filter] == "assistance_notice"
      filtered_operations = operations.where(assistance_submitted: false) if params[:filter] == "assistance_no_notice"
      filtered_operations = operations.where(assistance_paid: true) if params[:filter] == "assistance_paid"
      filtered_operations = operations.where(assistance_paid: false) if params[:filter] == "assistance_not_paid"
    else
      filtered_operations = operations
    end

    if params[:sort_by].present?
      sorted_operations = filtered_operations.order(created_at: :asc) if params[:sort_by] == "created_asc"
      sorted_operations = filtered_operations.order(created_at: :desc) if params[:sort_by] == "created_desc"
      sorted_operations = filtered_operations.order(bill_deadline: :asc) if params[:sort_by] == "due_asc"
      sorted_operations = filtered_operations.order_by_status if params[:sort_by] == "state"
    else
      sorted_operations = filtered_operations
    end


    @operations = sorted_operations || operations

    respond_to do |format|
      format.html { render :index}
      format.json { respond_with_bip(@operations) }
      format.js {}
    end
  end

  # GET /operations/1
  # GET /operations/1.json
  def show
  end

  # GET /operations/new
  def new
    @operation = Operation.new
  end

  # GET /operations/1/edit
  def edit
  end

  # POST /operations
  # POST /operations.json
  def create
    @operation = Operation.new(operation_params)

    respond_to do |format|
      if @operation.save
        format.html { redirect_to operations_path, notice: 'Vorgang wurde angelegt.' }
        format.json { render :index, status: :created, location: @operation }
      else
        format.html { render :new }
        format.json { render json: @operation.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /operations/1
  # PATCH/PUT /operations/1.json
  def update
    respond_to do |format|
      if @operation.update(operation_params)
        format.html { redirect_to @operation, notice: 'Operation was successfully updated.' }
        format.json { render :show, status: :ok, location: @operation }
      else
        format.html { render :edit }
        format.json { render json: @operation.errors.full_messages, status: :unprocessable_entity }
      end
    end
  end


def create_asset
  @bill = Image.new(params[:image_form])
  @bill.save
  render :text => @bill.public_filename
end

  # DELETE /operations/1
  # DELETE /operations/1.json
  def destroy
    @operation.destroy
    respond_to do |format|
      format.html { redirect_to operations_url, notice: 'Operation was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_operation
      @operation = Operation.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def operation_params
      params.require(:operation).permit(:title, :value, :insurance_paid, :insurance_submitted, :insurance_payback, :assistance_paid, :assistance_submitted, :assistance_payback, :billing_date, :content, :person_id, :bill, :bill_deadline, :insurance_notice, :paid)
    end
end
