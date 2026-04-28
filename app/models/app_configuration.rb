class AppConfiguration < Reptrack::Configuration
    preference :task_buckets, :array, default: [
     "today" ,
     "tomorrow",
     "overdue",
     "as soon as possible",
     "this week",
     "next week",
     "sometime later"
  ]
end 