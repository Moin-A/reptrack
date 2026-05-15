class HelloMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    Rails.logger.info "Hello — #{env["REQUEST_METHOD"]} #{env["PATH_INFO"]}"
    status, headers, response = @app.call(env)
    Rails.logger.info "Bye — #{env["REQUEST_METHOD"]} #{env["PATH_INFO"]} (#{status})"
    [status, headers, response]
  end
end
