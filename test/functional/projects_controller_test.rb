require File.expand_path('../../test_helper', __FILE__)

describe "On a ProjectsController, when updating" do
  tests ProjectsController
  
  before do
    @project = Project.create(:name => 'NestedParams')
    @project.tasks.create(:name => 'Check other implementations')
    @project.tasks.create(:name => 'Try with our plugin')
    @tasks = @project.tasks
    
    @valid_update_params = { :name => 'Dinner', :tasks => {
      @tasks.first.id => { :name => "Buy food" },
      @tasks.last.id  => { :name => "Cook" }
    }}
  end
  
  it "should update attributes of the nested tasks" do
    put :update, :id => @project.id, :project => @valid_update_params
    @project.reload
    
    @project.name.should == 'Dinner'
    @project.tasks.map(&:name).sort.should == ['Buy food', 'Cook']
  end
  
  it "should destroy a missing task" do
    @valid_update_params[:tasks].delete(@tasks.first.id)
    
    lambda {
      put :update, :id => @project.id, :project => @valid_update_params
    }.should.differ('Task.count', -1)
  end
  
  it "should add a new task" do
    @valid_update_params[:tasks]['new_12345'] = { :name => 'Take out' }
    
    lambda {
      put :update, :id => @project.id, :project => @valid_update_params
    }.should.differ('Task.count', +1)
  end
  
  it "should reject any new task that's empty" do
    @valid_update_params[:tasks]['new_12345'] = { :name => '', :due_at => nil }
    
    lambda {
      put :update, :id => @project.id, :project => @valid_update_params
    }.should.not.differ('Task.count')
    
    assigns(:project).should.be.valid
  end
  
  it "should destroy a missing task and add a new one" do
    @valid_update_params[:tasks].delete(@tasks.first.id)
    @valid_update_params[:tasks]['new_12345'] = { :name => 'Take out' }
    
    lambda {
      put :update, :id => @project.id, :project => @valid_update_params
    }.should.not.differ('Task.count')
  end
  
  it "should not be valid if a task is invalid" do
    put :update, :id => @project.id, :project => { :name => 'Nothing', :tasks => { @tasks.first.id => { :name => '' }, @tasks.last.id => { :name => '' }}}
    project = assigns(:project)
    
    project.should.not.be.valid
    project.errors.on(:tasks_name).should == "can't be blank"
    
    project.reload
    project.name.should == 'NestedParams'
  end
end