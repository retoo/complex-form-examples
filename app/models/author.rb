class Author < ActiveRecord::Base
  has_many :projects
  
  attr_accessor :raise_exception
  
  after_save :raise_exception_if_needed
  def raise_exception_if_needed
    if @raise_exception.to_i == 1
      raise 'Oh noes!'
    end
  end
end
