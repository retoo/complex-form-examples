class CreateAuthors < ActiveRecord::Migration
  def self.up
    create_table :authors do |t|
      t.integer :project_id
      t.string  :name
      t.timestamps
    end
    add_index :authors, :project_id
  end

  def self.down
    drop_table :authors
  end
end
