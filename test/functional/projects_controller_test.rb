require File.expand_path('../../test_helper', __FILE__)

describe "On a ProjectsController, when updating" do
  tests ProjectsController
  
  before do
    @project = Project.create(:name => 'NestedParams')
    @project.create_author(:name => 'Eloy')
    @project.tasks.create(:name => 'Check other implementations')
    @project.tasks.create(:name => 'Try with our plugin')
    @tasks = @project.tasks
    
    @valid_update_params = { :name => 'Dinner', :tasks_attributes => {
      @tasks.first.id => { :name => "Buy food" },
      @tasks.last.id  => { :name => "Cook" }
    }}
  end
  
  it "should update the name of the author" do
    put :update, :id => @project.id, :project => { :author_attributes => { :name => 'Mighty Mo' }}
    @project.reload.author.name.should == 'Mighty Mo'
  end
  
  it "should update attributes of the nested tasks" do
    put :update, :id => @project.id, :project => @valid_update_params
    @project.reload
    
    @project.name.should == 'Dinner'
    @project.tasks.map(&:name).sort.should == ['Buy food', 'Cook']
  end
  
  it "should destroy a missing task" do
    @valid_update_params[:tasks_attributes].delete(@tasks.first.id)
    
    lambda {
      put :update, :id => @project.id, :project => @valid_update_params
    }.should.differ('Task.count', -1)
  end
  
  it "should add a new task" do
    @valid_update_params[:tasks_attributes]['new_12345'] = { :name => 'Take out' }
    
    lambda {
      put :update, :id => @project.id, :project => @valid_update_params
    }.should.differ('Task.count', +1)
  end
  
  it "should reject any new task that's empty" do
    @valid_update_params[:tasks_attributes]['new_12345'] = { :name => '', :due_at => nil }
    
    lambda {
      put :update, :id => @project.id, :project => @valid_update_params
    }.should.not.differ('Task.count')
    
    assigns(:project).should.be.valid
  end
  
  it "should destroy a missing task and add a new one" do
    @valid_update_params[:tasks_attributes].delete(@tasks.first.id)
    @valid_update_params[:tasks_attributes]['new_12345'] = { :name => 'Take out' }
    
    lambda {
      put :update, :id => @project.id, :project => @valid_update_params
    }.should.not.differ('Task.count')
  end
  
  it "should not be valid if a task is invalid" do
    put :update, :id => @project.id, :project => { :name => 'Nothing', :tasks_attributes => { @tasks.first.id => { :name => '' }, @tasks.last.id => { :name => '' }}}
    project = assigns(:project)
    
    project.should.not.be.valid
    project.errors.on(:tasks_name).should == "can't be blank"
    
    project.reload
    project.name.should == 'NestedParams'
  end
  
  it "should rollback any changes to the project and tasks if an exception occurs in one of the tasks" do
    Task.any_instance.stubs(:save).raises
    
    lambda {
      put :update, :id => @project.id, :project => @valid_update_params
      @project.reload
    }.should.raise
    
    @project.name.should == 'NestedParams'
    @project.tasks.map(&:name).sort.should == ['Check other implementations', 'Try with our plugin']
  end
end