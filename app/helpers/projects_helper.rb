module ProjectsHelper
  def remove_link_unless_new_record(fields, record)
    unless record.new_record?
      out = ''
      out << fields.hidden_field(:_delete)
      out << link_to_function("remove", "$(this).up('.#{record.class.name.underscore}').hide(); $(this).previous().value = '1'")
      out
    end
  end
  
  def add_task_link(name, form)
    link_to_function name do |page|
      task = render(:partial => 'task', :locals => { :pf => form, :task => Task.new })
      page << %{
        var new_task_id = "new_" + new Date().getTime();
        $('tasks').insert({ bottom: "#{ escape_javascript task }".replace(/new_\\d+/g, new_task_id) });
      }
    end
  end
  
  def add_tag_link(name, form)
    link_to_function name do |page|
      tag = render(:partial => 'tag', :locals => { :pf => form, :tag => Tag.new })
      page << %{
        var new_tag_id = "new_" + new Date().getTime();
        $('tags').insert({ bottom: "#{ escape_javascript tag }".replace(/new_\\d+/g, new_tag_id) });
      }
    end
  end
end
