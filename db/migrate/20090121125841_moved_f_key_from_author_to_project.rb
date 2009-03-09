class MovedFKeyFromAuthorToProject < ActiveRecord::Migration
  def self.up
    remove_column :authors, :project_id
    add_column :projects, :author_id, :integer
  end

  def self.down
    remove_column :projects, :author_id
    add_column :authors, :project_id, :integer
  end
end
