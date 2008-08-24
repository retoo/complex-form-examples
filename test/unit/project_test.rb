require File.expand_path('../../test_helper', __FILE__)

describe "Project" do
  before do
    @valid_params = { :name => 'NestedParams', :tasks => [
      { :name => 'Check other implementations' },
      { :name => 'Try with our plugin' }
    ]}
    
    @project = Project.create(@valid_params)
    @tasks = @project.tasks
    
    @valid_update_params = { :name => 'Dinner', :tasks => {
      @tasks.first.id.to_s => { :name => "Buy food" },
      @tasks.last.id.to_s  => { :name => "Cook" }
    }}
  end
  
  it "should take a hash with tasks hashes and create Task records for them" do
    lambda do
      Project.create(@valid_params)
    end.should.differ('Project.count + Task.count', +3)
    
    @project.name.should == 'NestedParams'
    @project.tasks.map(&:name).sort.should == ['Check other implementations', 'Try with our plugin']
  end
  
  it "should update it's own attributes and the attributes of the child tasks" do
    @project.attributes = @valid_update_params
    
    @project.name.should == 'Dinner'
    @project.tasks.map(&:name).sort.should == ['Buy food', 'Cook']
  end
  
  it "should automatically save the tasks when the project is saved" do
    @project.name = 'NestedParams and AutosaveAssociation'
    @project.tasks.first.name = 'Just start!'
    @project.save!; @project.reload
    
    @project.name.should == 'NestedParams and AutosaveAssociation'
    @project.tasks.first.name.should == 'Just start!'
  end
  
  it "should rollback any changes to the project and tasks if an exception occurs in one of the tasks" do
    Task.any_instance.stubs(:save).raises(Exception, 'Oh noes!')
    
    @project.attributes = @valid_update_params
    @project.save
    
    @project.reload
    
    @project.name.should == 'NestedParams'
    @project.tasks.map(&:name).sort.should == ['Check other implementations', 'Try with our plugin']
  end
end