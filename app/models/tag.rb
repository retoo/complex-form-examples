class Tag < ActiveRecord::Base
  validates_presence_of :name, :message => "can't just be blank"
end
