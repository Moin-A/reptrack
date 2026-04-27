class TasksController < ApplicationController
  before_action :set_task, only: %i[ show update destroy ]

  # GET /tasks
  def index
    render json: {
      tasks: [
        { id: 1, name: "My first Task",        due: "6 days late — was due Apr 16 at 12:00 AM", overdue: true,  badge: "Lunch",   badgeColor: "#6AAF5E", badgeTextColor: "white", done: false },
        { id: 2, name: "Follow up with Priya", due: "Due today at 3:00 PM",                     overdue: false, badge: "Call",    badgeColor: "#2F6FEB", badgeTextColor: "white", done: false },
        { id: 3, name: "Review Q2 proposal",   due: "Due Apr 25",                               overdue: false, badge: "Meeting", badgeColor: "#7C3AED", badgeTextColor: "white", done: false },
      ],
      metadata: {
        buckets: Reptrack.config.task_buckets
      }
    }
  end

  # GET /tasks/1
  def show
    render json: @task
  end

  # POST /tasks
  def create
    @task = Task.new(task_params)

    if @task.save
      render json: @task, status: :created, location: @task
    else
      render json: @task.errors, status: :unprocessable_content
    end
  end

  # PATCH/PUT /tasks/1
  def update
    if @task.update(task_params)
      render json: @task
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

    # Only allow a list of trusted parameters through.
    def task_params
      params.require(:task).permit(:name, :description, :due_date, :status)
    end
end
