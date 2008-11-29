class Project < ActiveRecord::Base
  # Automatically turns on autosave and thus also validates
  has_one :author, :accept_nested_attributes => true
  has_many :tasks, :dependent => :destroy, :accept_nested_attributes => true, :destroy_missing => true
  has_and_belongs_to_many :tags, :accept_nested_attributes => true, :destroy_missing => true
  
  validates_presence_of :name
end
