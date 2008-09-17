require File.expand_path('../autosave_association', __FILE__)

# Adds <tt>:nested_params</tt>, <tt>:reject_empty</tt> and <tt>:destroy_missing</tt> to the options for <tt>has_one</tt> and <tt>has_many</tt> associations.
# Which allows attributes of the associated model to be set directly
# with a hash to ActiveRecord::Base#attributes=.
# This is handy for when you have a form consisting of a parent and one or more child records.
#
# All the associations that you enable <tt>:nested_params</tt> on, will automatically have <tt>:autosave</tt> turned on as well.
# See AutosaveAssociation for more info.
#
# Examples for a has_one association:
#
#   class Member < ActiveRecord::Base
#     extend NestedParams
#     has_one :avatar, :nested_params => true
#   end
#
#   # Adding an associated model:
#   params[:member] # => { 'name' => 'jack', 'avatar' => { 'name' => 'smiley' }}
#
#   member = Member.create(params[:member])
#   member.avatar.name # => 'smiley'
#   
#   # Updating the associated model:
#   params # => { 'id' => '1', 'member' => { 'name' => 'joe', 'avatar' => { 'name' => 'sadly' }}}
#
#   member = Member.find(params[:id])
#   member.update_attributes params[:member]
#   member.avatar.name # => 'sadly'
#
# Examples for a has_many association:
#
#   class Member < ActiveRecord::Base
#     extend NestedParams
#     has_many :posts, :nested_params => true, :destroy_missing => true, :reject_empty => true
#   end
#
#   # Creating associated models. Use the :reject_empty option to not create associated models for any empty hashes (Turned off by default):
#   params[:member] # => { 'name' => 'joe', 'posts' => {
#     'new_12345' => { 'title' => 'first psot' },
#     'new_54321' => { 'title' => 'other post' },
#     'new_67890' => { 'title' => '' } # This one is empty and will be rejected.
#   }}
#
#   member = Member.create(params[:member])
#   member.posts.length # => 2
#   member.posts.first.title # => 'first psot'
#   member.posts.last.title # => 'other post'
#
#   # Updating the associated models:
#   params[:member] # => { 'name' => 'joe', 'posts' => {
#     '1' => { 'title' => '[UPDATED] first psot' },
#     '2' => { 'title' => '[UPDATED] other post' }
#   }}
#
#   member.update_attributes params[:member]
#   member.posts.first.title # => '[UPDATED] first psot'
#   member.posts.last.title # => '[UPDATED] other post'
#
#   # Destroy an associated model by leaving it out of the attributes hash. Turn it on with the :destroy_missing option (Turned off by default):
#   params[:member] # => { 'name' => 'joe', 'posts' => {
#     '2' => { 'title' => '[UPDATED] other post is now the only post' }
#   }}
#
#   member.update_attributes params[:member]
#   member.posts.length # => 1
#   member.posts.first.title # => '[UPDATED] other post is now the only post'
module NestedParams
  def has_many_with_nested_params(*args)
    if (options = args.last).is_a?(Hash)
      destroy_missing = options.delete(:destroy_missing)
      nested_params   = options.delete(:nested_params)
      reject_empty    = options.delete(:reject_empty)
    end
    
    has_many_without_nested_params(*args)
    
    if nested_params
      attr = args.first
      define_nested_params_for_has_many_association(attr, destroy_missing, reject_empty)
      define_autosave_and_validation_for_has_many_association(attr)
    end
  end
  
  def has_one_with_nested_params(*args)
    nested_params = args.last.delete(:nested_params) if args.last.is_a?(Hash)
    has_one_without_nested_params(*args)
    if nested_params
      attr = args.first
      define_nested_params_for_has_one_association(attr)
      define_autosave_and_validation_for_has_one_association(attr)
    end
  end
  
  def define_nested_params_for_has_many_association(attr, destroy_missing, reject_empty)
    class_eval do
      define_method("#{attr}_with_nested_params=") do |value|
        if value.is_a?(Hash) || value.is_a?(ActiveSupport::OrderedHash)
          if destroy_missing
            # Get all ids and subtract the ones we received, destroy the remainder
            keys = value.keys.map { |key| key.to_s }
            send(attr).reject { |x| keys.include? x.id.to_s }.each { |record| record.destroy }
          end
          
          new_records = []
          value.each do |id, attributes|
            if id.is_a?(String) && id.starts_with?('new_')
              # Collect new records marked by an id that starts with 'new_
              new_records << [id, attributes] unless reject_empty && attributes.values.all? { |v| v.blank? }
            else
              # Find the existing record for this id and assign the attributes
              send(attr).detect { |x| x.id == id.to_i }.attributes = attributes
            end
          end
          # Sort and build new records
          new_records.sort_by { |id, _| id }.each { |_, attributes| send(attr).build attributes }
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