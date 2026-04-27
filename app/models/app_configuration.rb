class AppConfiguration < Reptrack::Configuration
    preference :task_buckets, :array, default: [
     "today" ,
     "tomorrow"
  ]
end 