class TaskSerializer
  include JSONAPI::Serializer

  attributes :id, :name, :description, :due_date, :status, :bucket

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
