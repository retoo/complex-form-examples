require File.expand_path('../autosave_association', __FILE__)

# Adds :nested_params to the options for has_one and has_many associations,
# which allows attributes of the associated model to be set directly
# with a hash to #attributes=.
#
# This is handy for when you have a form consisting of a parent and one or more child records.
#
# All the associations that you enable :nested_params on, will automatically have :autosave turned on as well.
# See AutosaveAssociation for more info.
#
# Example of a has_one association:
#
#   class Member < ActiveRecord::Base
#     extend NestedParams
#     has_one :avatar, :nested_params => true
#   end
#
#   params[:member] # => { 'name' => 'joe', 'avatar' => { 'name' => 'sadly' }}
#
#   member.update_attributes params[:member]
#   member.reload;
#
#   member.avatar.name # => 'sadly'
#
# Example of a has_many association:
#
#   class Member < ActiveRecord::Base
#     extend NestedParams
#     has_many :avatars, :nested_params => true
#   end
#
#   params[:member] # => { 'name' => 'joe', 'avatars' => { '1' => { 'name' => 'sadly' }, '2' => { 'name' => 'smiley' }}}
#   member.update_attributes params[:member]
#
#   Avatar.find(1).name # => 'sadly'
#   Avatar.find(2).name # => 'smiley'
module NestedParams
  def has_many_with_nested_params(*args)
    if (options = args.last).is_a?(Hash)
      nested_params   = options.delete(:nested_params)
      destroy_missing = options.delete(:destroy_missing)
    end
    
    has_many_without_nested_params(*args)
    
    if nested_params
      attr = args.first
      define_nested_params_for_has_many_association(attr, destroy_missing)
      define_autosave_for_has_many_association(attr)
    end
  end
  
  def define_nested_params_for_has_many_association(attr, destroy_missing = false)
    class_eval do
      define_method("#{attr}_with_nested_params=") do |value|
        if value.is_a? Hash
          if destroy_missing
            association = send(attr)
            # Get all ids and subtract the ones we received, detroy the remainder
            keys = value.keys
            association.reject { |x| keys.include? x.id.to_s }.each { |record| record.destroy }
          end
          
          # For existing records and new records that are marked by an id that starts with 'new_'
          value.each do |id, attributes|
            association ||= send(attr)
            if id.starts_with? 'new_'
              association.build attributes
            else
              # Find the record for this id and assign the attributes
              association.detect { |x| x.id == id.to_i }.attributes = attributes
            end
          end
        else
          if value.is_a?(Array) && value.all? { |x| x.is_a?(Hash) }
            # For an array full of new record hashes
            value.each do |attributes|
              send(attr).build attributes
            end
          else
            # For existing instaniated records and all other stuff people might pass
            send("#{attr}_without_nested_params=", value)
          end
        end
      end
    end
    
    alias_method_chain("#{attr}=", :nested_params)
  end
  
  def has_one_with_nested_params(*args)
    nested_params = args.last.delete(:nested_params) if args.last.is_a?(Hash)
    has_one_without_nested_params(*args)
    if nested_params
      attr = args.first
      define_nested_params_for_has_one_association(attr)
      define_autosave_for_has_one_association(attr)
    end
  end
  
  def define_nested_params_for_has_one_association(attr)
    class_eval do
      define_method("#{attr}_with_nested_params=") do |value|
        if value.is_a? Hash
          send("build_#{attr}") if send(attr).nil?
          send(attr).attributes = value
        else
          send("#{attr}_without_nested_params=", value)
        end
      end
    end
    
    alias_method_chain("#{attr}=", :nested_params)
  end
  
  def self.extended(klass)
    klass.extend AutosaveAssociation
    class << klass
      alias_method_chain :has_many, :nested_params
      alias_method_chain :has_one,  :nested_params
    end
  end
end