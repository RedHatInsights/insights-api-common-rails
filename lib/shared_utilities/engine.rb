require 'rails'
module SharedUtilities
  class Engine < Rails::Engine
    #isolate_namespace SharedUtilities
    config.autoload_paths += Dir["#{SharedUtilities::Engine.root}/lib/"]
    config.autoload_paths += Dir["#{SharedUtilities::Engine.root}/lib/**/"]
    config.eager_load_paths += %W( #{SharedUtilities::Engine.root}/lib )
  end
end
