class NestedParamsFormBuilder < ActionView::Helpers::FormBuilder
  def fields_for(record_or_name_or_array, *args, &block)
    if record_or_name_or_array.is_a?(String) || record_or_name_or_array.is_a?(Symbol)
      if reflection = @object.class.reflect_on_association(record_or_name_or_array.to_sym)
        name = "#{object_name}[#{record_or_name_or_array}_attributes]"
        
        case reflection.macro
        when :has_one then return @template.fields_for(name, @object.send(record_or_name_or_array), *args, &block)
        when :has_many
          records = args.first.is_a?(ActiveRecord::Base) ? [args.first] : @object.send(record_or_name_or_array)
          return records.map do |record|
            # In the case of a new object use a fictive id which is composited with "new_" and the @child_counter.
            record_name = "#{name}[#{ record.new_record? ? "new_#{child_counter}" : record.id }]"
            @template.fields_for(record_name, record, *args) do |form_builder|
              block.arity == 2 ? block.call(form_builder, record) : block.call(form_builder)
            end
          end.join
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