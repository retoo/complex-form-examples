require 'rubygems'
require 'test/spec'
require 'mocha'
require 'activerecord'

$: << File.expand_path('../../lib', __FILE__)
require 'nested_params'

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :dbfile => ":memory:")
ActiveRecord::Migration.verbose = false
# ActiveRecord::Base.logger = Logger.new($stdout)
# ActiveRecord::Base.logger.level = Logger::DEBUG

def setup_db
  ActiveRecord::Schema.define(:version => 1) do
    create_table :members do |t|
      t.column :email, :string
      t.column :address, :string
    end
    
    create_table :visitors do |t|
      t.column :email, :string
      t.column :address, :string
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
  has_many :artists, :nested_params => true, :destroy_missing => true, :reject_empty => true
  
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