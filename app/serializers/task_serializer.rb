class TaskSerializer
  include JSONAPI::Serializer

  attributes :id, :name, :description, :due_date, :status, :bucket

  attribute :user do |task|
    task.user && { id: task.user.id, name: task.user.name, email: task.user.email }
  end

  attribute :assignee do |task|
    task.assignee && { id: task.assignee.id, name: task.assignee.name, email: task.assignee.email }
  end

  def self.normalize(task)
    new(task).serializable_hash[:data][:attributes]
  end

  def self.grouped_by_bucket
    Task.buckets.keys.to_h do |bucket|
    tasks = new(Task.in_bucket(bucket)).serializable_hash[:data].map { |t| t[:attributes] }
        [ bucket, tasks ]
    end
  end
end
