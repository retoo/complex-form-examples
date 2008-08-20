class Project < ActiveRecord::Base
  use_nested_params = true
  
  if use_nested_params
    puts 'Using NestedParams'
    
    extend NestedParams
    
    # Automatically turns on autosave and thus also validates
    has_many :tasks, :dependent => :destroy, :nested_params => true
    
    validates_presence_of :name
  else
    puts 'Using :accessible'
    has_many :tasks, :dependent => :destroy, :accessible => true
    
    validates_presence_of :name
    #validates_associated :tasks, :on => :update # automatically validated on create
  end
end
