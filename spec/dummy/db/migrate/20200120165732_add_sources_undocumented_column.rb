class AddSourcesUndocumentedColumn < ActiveRecord::Migration[5.2]
  def change
    add_column :sources, :undocumented, :string
  end
end
