  class TasksController < ApplicationController
  load_and_authorize_resource
  before_action :log_params

  # GET /tasks
  def index
    buckets, pagy_by_bucket = TaskSerializer.grouped_by_bucket do |bucket|
      pagy(Task.incomplete.in_bucket(bucket), page: page(bucket), limit: 5)
    end

    pagination = pagy_by_bucket.transform_values do |p|
      { page_no: p.page, total_items: p.count, per_page: p.limit }
    end

    render json: { buckets: buckets, pagination: pagination }
  end

  # GET /tasks/1
  def show
    render json: @task
  end

  # POST /tasks
  def create
    @task = Task.new(task_params)
    @task.user = current_user
    if @task.save
      render json: TaskSerializer.normalize(@task), status: :created, location: @task
    else
      render json: @task.errors, status: :unprocessable_content
    end
  end

  def complete
   if @task.update(status: :completed, completor: current_user, completed_at: Time.current)
      render json: TaskSerializer.normalize(@task)
   else
      render json: @task.errors, status: :unprocessable_content
   end
  end

  # PATCH/PUT /tasks/1
  def update
    if @task.update(task_params)
      render json: TaskSerializer.normalize(@task)
    else
      render json: @task.errors, status: :unprocessable_content
    end
  end

  # DELETE /tasks/1
  def destroy
    @task.destroy!
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_task
      @task = Task.find(params[:id])
    end

    def page(bucket)
      pagination_params.dig(bucket.to_sym, :page_no) || 1
    end

    # Only allow a list of trusted parameters through.
    def task_params
      params.require(:task).permit(:name, :description, :due_date, :status, :bucket, :assignee_id)
    end

    def pagination_params
      allowed = Task.buckets.keys.map(&:to_sym)
      params.fetch(:pagination, {}).permit(
          allowed.index_with { [ :page_no, :per_page ] }
      )
    end

    def log_params
      Rails.logger.debug "PARAMS: #{params.inspect}"
    end
  end
