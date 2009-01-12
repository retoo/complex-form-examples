class Project < ActiveRecord::Base
  has_one :author
  has_many :tasks, :dependent => :destroy
  has_and_belongs_to_many :tags
  
  # Automatically turns on autosave and thus also validates
  accept_nested_attributes_for :author
  accept_nested_attributes_for :tasks, :tags, :allow_destroy => true, :reject_if => proc { |a| a['name'].blank? }
  
  validates_presence_of :name
end
