class AddApplicationsAndApplicationTypes < ActiveRecord::Migration[5.2]
  def change
    create_table :application_types do |t|
      t.string :name, :null => false
      t.string :display_name
      t.index %w[name], :unique => true
      t.timestamps
    end

    create_table :applications do |t|
      t.string :availability_status
      t.string :availability_status_error
      t.references :tenant,           :index => true, :null => false, :foreign_key => {:on_delete => :cascade}
      t.references :source,           :index => true, :null => false, :foreign_key => {:on_delete => :cascade}
      t.references :application_type, :index => true, :null => false, :foreign_key => {:on_delete => :cascade}
      t.timestamps
    end
  end
end
