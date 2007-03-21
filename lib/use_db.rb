# UseDb

module UseDbPlugin
  # options can have one or the other of the following options:
  #   :prefix - Specify the prefix to append to the RAILS_ENV when finding the adapter secification in database.yml
  #   :suffix - Just like :prefix, only contactentated
  # OR
  #   :adapter
  #   :host
  #   :username
  #   :password
  #     ... etc ... same as the options in establish_connection
  
  @@use_dbs = [ActiveRecord::Base]
  
  def use_db(options)
    options_dup = options.dup
    conn_spec = get_use_db_conn_spec(options)
    puts "Establishing connecting on behalf of #{self.to_s} to #{conn_spec.inspect}"
    establish_connection(conn_spec)
    extend ClassMixin
    @@use_dbs << self unless @@use_dbs.include?(self) || self.to_s.starts_with?("TestModel")
  end
  
  def self.all_use_dbs
    return @@use_dbs
  end
  
  module ClassMixin
    def uses_db?
      true
    end
  end
  
  private
  
  def get_use_db_conn_spec(options)
    options.symbolize_keys
    suffix = options.delete(:suffix)
    prefix = options.delete(:prefix)
    rails_env = options.delete(:rails_env) || RAILS_ENV
    if (options[:adapter])
      return options
    else
      str = "#{prefix}#{rails_env}#{suffix}"
      connections = YAML.load(File.read "#{RAILS_ROOT}/config/database.yml")
      raise "Cannot find database specification.  Configuration '#{str}' expected in config/database.yml" if (connections[str].nil?)      
      return connections[str]
    end
  end
end