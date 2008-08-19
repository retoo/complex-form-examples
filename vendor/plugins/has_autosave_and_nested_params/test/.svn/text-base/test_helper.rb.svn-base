require 'rubygems'
require 'test/spec'
require 'activerecord'
require File.expand_path('../../lib/nested_params', __FILE__)

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :dbfile => ":memory:")
ActiveRecord::Migration.verbose = false

def setup_db
  ActiveRecord::Schema.define(:version => 1) do
    create_table :members do |t|
      t.column :email, :string
    end
    
    create_table :visitors do |t|
      t.column :email, :string
    end
    
    create_table :artists do |t|
      t.integer :member_id
      t.integer :visitor_id
      t.string  :name
    end
    
    create_table :avatars do |t|
      t.integer :member_id
      t.integer :visitor_id
      t.string  :name
    end
  end
end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

class Member < ActiveRecord::Base
  extend NestedParams
  has_one :artist, :nested_params => true
  
  extend AutosaveAssociation
  has_one :avatar, :autosave => true
end

class Visitor < ActiveRecord::Base
  extend NestedParams
  has_many :artists, :nested_params => true
  
  extend AutosaveAssociation
  has_many :avatars, :autosave => true
end

class Artist < ActiveRecord::Base
  belongs_to :member
  
  validates_presence_of :name
end

class Avatar < ActiveRecord::Base
  belongs_to :member
  
  validates_presence_of :name
end