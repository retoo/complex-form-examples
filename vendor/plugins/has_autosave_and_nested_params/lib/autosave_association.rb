# Adds :autosave to the options for has_one and has_many associations,
# which will automatically save the associated models after
# the parent has been saved.
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
    define_autosave_for_has_many_association(args.first) if autosave
  end
  
  def define_autosave_for_has_many_association(attr)
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
  
  def has_one_with_autosave(*args)
    autosave = args.last.delete(:autosave) if args.last.is_a?(Hash)
    has_one_without_autosave(*args)
    define_autosave_for_has_one_association(args.first) if autosave
  end
  
  # Defines the method that will save the association after the model is saved.
  # Also defines a validation method for the association which will add any errors
  # of the association to the models errors.
  def define_autosave_for_has_one_association(attr)
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
  
  def self.extended(klass)
    return if klass.respond_to? :has_one_without_autosave
    class << klass
      alias_method_chain :has_many, :autosave
      alias_method_chain :has_one,  :autosave
    end
    
    klass.class_eval do
      def save_with_autosave(run_validations = true)
        self.class.transaction { run_validations ? save! : save_without_autosave(false) }
        true
      rescue
        # TODO: We rescue everything.. Is that ok? Or should we only rescue certain exceptions?
        false
      end
      
      alias_method_chain :save, :autosave
    end
  end
end