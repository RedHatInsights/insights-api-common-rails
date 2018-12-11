class Create<%= table_name.camelize %> < ActiveRecord::Migration<%= migration_version %>
  def change
    create_table :<%= table_name %><%= primary_key_type %> do |t|
      t.references "resource", :polymorphic => true, :index => true
      t.string     :name
      t.string     :authtype
      t.string     :status
      t.string     :status_details
      t.bigint     :tenant_id

      t.timestamps
    end

    create_table :encryptions<%= primary_key_type %> do |t|
      t.references "<%= table_name %>", :index => true
      t.string :secret
      t.bigint :tenant_id

      t.timestamps
    end
  end
end
