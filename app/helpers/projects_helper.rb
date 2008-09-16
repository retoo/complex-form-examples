module ProjectsHelper
  def add_task_link(name, form)
    link_to_function name do |page|
      task = render(:partial => 'task', :locals => { :pf => form, :task => Task.new })
      page << %{
        var new_task_id = "new_" + new Date().getTime();
        $('tasks').insert({ bottom: "#{ escape_javascript task }".replace(/new_\\d+/g, new_task_id) });
      }
    end
  end
end
