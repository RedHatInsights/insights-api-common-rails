class CreateTasks < ActiveRecord::Migration[5.2]
  def change
    create_table :tasks, :id => :uuid do |t|
      t.references :tenant, :index => true, :null => false
      t.references :source, :index => true, :null => true, :foreign_key => {:on_delete => :nullify}
      t.string :name
      t.string :status
      t.string :state
      t.string :message
    end
  end
end
