module DbSchema
  class Configuration
    attr_reader :adapter, :host, :port, :database, :user, :password

    def initialize(adapter: 'postgres', host: 'localhost', port: 5432, database:, user: nil, password: '', log_changes: true, dry_run: false, post_check: true)
      @adapter     = adapter
      @host        = host
      @port        = port
      @database    = database
      @user        = user
      @password    = password
      @log_changes = log_changes
      @dry_run     = dry_run
      @post_check  = post_check
    end

    def log_changes?
      @log_changes
    end

    def dry_run?
      @dry_run
    end

    def post_check_enabled?
      @post_check
    end
  end
end
