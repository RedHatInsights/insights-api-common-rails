require 'rails'
module SharedUtilities
  class Engine < Rails::Engine
    #isolate_namespace SharedUtilities
    #config.autoload_paths += Dir["#SharedUtilities::Engine.root}/app/"]
    #config.autoload_paths += Dir["#SharedUtilities::Engine.root}/app/models/"]
    #config.autoload_paths += Dir["#SharedUtilities::Engine.root}/app/models/concerns/"]
    #config.autoload_paths += Dir["#{SharedUtilities::Engine.root}/lib/"]
    #config.autoload_paths += Dir["#{SharedUtilities::Engine.root}/lib/**/"]

    #config.to_prepare do
    #  ActiveRecord::Base.include Authentication
    #end
  end
end
