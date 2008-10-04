class Project < ActiveRecord::Base
  # Automatically turns on autosave and thus also validates
  has_one :author, :nested_params => true
  has_many :tasks, :dependent => :destroy, :nested_params => true, :destroy_missing => true
  
  validates_presence_of :name
end
