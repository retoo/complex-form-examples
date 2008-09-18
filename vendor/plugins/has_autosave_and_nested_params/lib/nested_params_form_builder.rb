class NestedParamsFormBuilder < ActionView::Helpers::FormBuilder
  def fields_for(record_or_name_or_array, *args, &block)
    if record_or_name_or_array.is_a?(String) || record_or_name_or_array.is_a?(Symbol)
      if reflection = @object.class.reflect_on_association(record_or_name_or_array.to_sym)
        case reflection.macro
        when :has_one
          name = "#{object_name}[#{record_or_name_or_array}_attributes]"
          return @template.fields_for(name, @object.send(record_or_name_or_array), *args, &block)
        when :has_many
          record = args.first
          # In the case of a new object use a fictive id which is composited with "new_" and the @child_counter.
          name = "#{object_name}[#{record_or_name_or_array}_attributes][#{ record.new_record? ? "new_#{child_counter}" : record.id}]"
          return @template.fields_for(name, *args, &block)
        end
      end
    end
    super
  end
  
  private
  
  def child_counter
    value = (@child_counter ||= 1)
    @child_counter += 1
    value
  end
end