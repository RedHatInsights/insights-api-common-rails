ENV['SHARED_ENV'] ||= "development"

require 'bundler/setup'
Bundler.require(:default, ENV['SHARED_ENV'])
databases = YAML.load_file("config/database.yml")
ActiveRecord::Base.establish_connection(databases[ENV['SHARED_ENV']])
