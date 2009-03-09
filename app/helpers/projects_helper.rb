module ProjectsHelper
  def remove_link_unless_new_record(fields)
    unless fields.object.new_record?
      out = ''
      out << fields.hidden_field(:_delete)
      out << link_to_function("remove", "$(this).up('.#{fields.object.class.name.underscore}').hide(); $(this).previous().value = '1'")
      out
    end
  end
  
  # This method demonstrates the use of the :child_index option to render a
  # form partial for, for instance, client side addition of new nested
  # records.
  #
  # This specific example creates a link which uses javascript to add a new
  # form partial to the DOM.
  #
  #   <% form_for @project do |project_form| -%>
  #     <div id="tasks">
  #       <% project_form.fields_for :tasks do |task_form| %>
  #         <%= render :partial => 'task', :locals => { :f => task_form } %>
  #       <% end %>
  #     </div>
  #   <% end -%>
  def add_record_link(form_builder, method, caption, options = {})
    options[:object] ||= form_builder.object.class.reflect_on_association(method).klass.new
    options[:partial] ||= method.to_s.singularize
    options[:form_builder_local] ||= :f
    options[:insert] ||= method
    
    link_to_function(caption) do |page|
      form_builder.fields_for(method, options[:object], :child_index => 'NEW_RECORD') do |f|
        html = render(:partial => options[:partial], :locals => { options[:form_builder_local] => f })
        page << %{
          $('#{options[:insert]}').insert({
            bottom: '#{escape_javascript(html)}'.replace(/NEW_RECORD/g, new Date().getTime())
          });
        }
      end
    end
  end
end
