class TaskSerializer
  include JSONAPI::Serializer
  include Normalizable
  attributes :id, :name, :description, :due_date, :status, :bucket

  attribute :user do |task|
    task.user && { id: task.user.id, name: task.user.name, email: task.user.email }
  end

  attribute :assignee do |task|
    task.assignee && { id: task.assignee.id, name: task.assignee.name, email: task.assignee.email }
  end

  

  def self.grouped_by_bucket(&block)
    pagy_by_bucket = {}
    tasks_lists = Task.buckets.keys.to_h do |bucket|
      pagy, list = paginate_list(bucket, &block)
      pagy_by_bucket[bucket] = pagy
      [bucket, normalised_list(list)]
    end

    [tasks_lists, pagy_by_bucket]
  end

  private
  def self.normalised_list(list)
    list.map { |t| normalize(t) }
  end

  def self.paginate_list(bucket)
    if block_given?
      yield(bucket)
    else
      page = pagination_params.dig(bucket.to_sym, :page_no) || 1
      pagy(Task.in_bucket(bucket), page: page, limit: 5)
    end
  end
end
