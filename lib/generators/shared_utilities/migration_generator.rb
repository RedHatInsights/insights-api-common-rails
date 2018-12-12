require "rails/generators/active_record"
require 'rails/generators/migration'
require 'generators/shared_utilities/orm_helper'
module SharedUtilities
  class MigrationGenerator < Rails::Generators::NamedBase
    include ActiveRecord::Generators::Migration
    include Rails::Generators::Migration
    include SharedUtilities::OrmHelper

    argument :attributes, type: :array, default: [], banner: "field:type field:type"

    class_option :primary_key_type, type: :string, desc: "The type for primary key"

    source_root File.expand_path("../templates", __FILE__)

    def initialize(args, *options)
      raise StandardError, "Only 'authentication' model is currently implemented" if args.first != "authentication"
      super
    end

    def manifest
      copy_migration
    end

    def copy_migration
      if (behavior == :invoke && model_exists?) || (behavior == :revoke && migration_exists?(table_name))
        migration_template "migration_existing.rb", "#{migration_path}/update_authentications_on_#{table_name}.rb", migration_version: migration_version
      else
        migration_template "migration.rb", "#{migration_path}/create_#{table_name}.rb", migration_version: migration_version
      end
    end

    def migration_data
<<RUBY
   ## Required
      #  t.references "resource", :polymorphic => true, :index => true
      #  t.string       :name
      #  t.string       :authtype
      #  t.string       :status
      #  t.string       :status_details
      #  t.#{ip_column}     :tenant_id
      #  t.timestamps
RUBY
    end

    def ip_column
      # Padded with spaces so it aligns nicely with the rest of the columns.
      "%-8s" % (inet? ? "inet" : "string")
    end

    def inet?
     postgresql?
    end

    def rails5?
      Rails.version.start_with? '5'
    end

    def postgresql?
      config = ActiveRecord::Base.configurations[Rails.env]
      config && config['adapter'] == 'postgresql'
    end

    def primary_key_type
       primary_key_string if rails5?
    end

    def primary_key_string
      key_string = options[:primary_key_type] || "bigserial"
      ", id: :#{key_string}" if key_string
    end

    def migration_version
      if rails5?
        "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
      end
    end
  end
end
