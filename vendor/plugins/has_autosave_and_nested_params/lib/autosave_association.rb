# Adds <tt>:autosave</tt> to the options for has_one and has_many associations.
# Which will automatically save the associated models after
# the parent has been saved, but only if all validations pass on both
# the parent and the assocatiated models.
#
# All saving will be done within a transaction, so an exception raised in one
# of the associated models should not leave the db in an inconsistent state.
#
# Note that using ActiveRecord#save(false) on the parent to bypass validations, will also
# bypass any validations on the associated models.
#
# Example of a has_one association:
#
#   class Member < ActiveRecord::Base
#     extend AutosaveAssociation
#     has_one :avatar, :autosave => true
#   end
#
#   member.avatar.name # => 'smiley'
#   member.avatar.name = 'sadly'
#
#   member.save
#   member.reload
#
#   member.avatar.name # => 'sadly'
#
# Example of a has_many association:
#
#   class Member < ActiveRecord::Base
#     extend AutosaveAssociation
#     has_many :avatars, :autosave => true
#   end
#
#   member.avatars.map(&:name) # => ['smiley', 'frowny']
#
#   member.avatars.first.name = 'sadley'
#   member.avatars.last.name = 'browny'
#
#   member.save
#   member.reload
#
#   member.avatars.map(&:name) # => ['sadley', 'browny']
module AutosaveAssociation
  def has_many_with_autosave(*args)
    autosave = args.last.delete(:autosave) if args.last.is_a?(Hash)
    has_many_without_autosave(*args)
    define_autosave_and_validation_for_has_many_association(args.first) if autosave
  end
  
  def has_one_with_autosave(*args)
    autosave = args.last.delete(:autosave) if args.last.is_a?(Hash)
    has_one_without_autosave(*args)
    define_autosave_and_validation_for_has_one_association(args.first) if autosave
  end
  
  def define_autosave_and_validation_for_has_many_association(attr)
    class_eval do
      define_method("autosave_#{attr}") do
        send(attr).each { |x| x.save(false) }
      end
      after_save "autosave_#{attr}"
    end
    
    define_method("validate_#{attr}") do
      send(attr).each do |associated_model|
        unless associated_model.valid?
          associated_model.errors.each do |attribute, message|
            name = "#{attr}_#{attribute}"
            errors.add(name, message) if errors.on(name).blank?
          end
        end
      end
    end
    validate "validate_#{attr}"
  end
  
  def define_autosave_and_validation_for_has_one_association(attr)
    class_eval do
      define_method("autosave_#{attr}") do
        if associated_model = send(attr)
          associated_model.save(false)
        end
      end
      after_save "autosave_#{attr}"
      
      define_method("validate_#{attr}") do
        if (associated_model = send(attr)) and not associated_model.valid?
          associated_model.errors.each { |attribute, message| errors.add attribute, message }
        end
      end
      validate "validate_#{attr}"
    end
  end
  
  module InstanceMethods
    def save_with_autosave(run_validations = true)
      transaction { run_validations ? save! : save_without_autosave(false) }
      true
    rescue Exception => e
      # TODO: We rescue everything.. Is that ok? Or should we only rescue certain exceptions?
      false
    end
    
    def self.included(klass)
      klass.class_eval { alias_method_chain :save, :autosave }
    end
  end
  
  def self.extended(klass)
    return if klass.respond_to? :has_one_without_autosave
    class << klass
      alias_method_chain :has_many, :autosave
      alias_method_chain :has_one,  :autosave
    end
    klass.send(:include, InstanceMethods)
  end
end