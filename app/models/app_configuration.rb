class AppConfiguration < Reptrack::Configuration
   preference :audit_trail_defaults, :hash, default: { on: [ :create, :update, :destroy ] }
end
