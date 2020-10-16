class OperationsController < ApplicationController
  before_action :set_operation, only: [:show, :edit, :update, :destroy]

  # GET /operations
  # GET /operations.json
  def index
    users_operations = Operation.where(person_id: [current_user.people])
    @operations = users_operations.open_operations
    @closed_operations = users_operations.closed_operations
    @on_hold_operations = users_operations.on_hold_operations
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
