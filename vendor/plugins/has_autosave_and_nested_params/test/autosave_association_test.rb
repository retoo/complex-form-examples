require File.expand_path('../test_helper', __FILE__)

describe "AutosaveAssociation, on a has_one association" do
  before do
    setup_db
    
    @member = Member.create(:email => 'paco@example.com')
    @avatar = @member.create_avatar(:name => 'smiley')
  end
  
  after do
    teardown_db
  end
  
  it "should still work as normal" do
    @member.email = 'pablo@example.com'
    @member.save!; @member.reload
    @member.email.should == 'pablo@example.com'
  end
  
  it "should also still work without an associated model" do
    member = Member.create(:email => '')
    member.email = 'pablo@example.com'
    lambda { member.save! }.should.not.raise Exception
  end
  
  it "should automatically save the associated model" do
    @member.avatar.name = 'sadly'
    @member.save!; @member.reload
    @member.avatar.name.should == 'sadly'
  end
  
  it "should automatically validate the associated model" do
    @member.avatar.name = ''
    @member.should.not.be.valid
    @member.errors.on(:name).should.not.be.blank
  end
  
  it "should rollback any changes if an exception occurred while saving" do
    @member.avatar.stubs(:save).raises(RuntimeError, 'Error!')
    
    @member.avatar.visitor_id = 123
    @member.address = 'Another address 1'
    
    lambda {
      @member.save.should.be false
    }.should.not.raise(Exception)
    
    @member.reload
    @member.address.should.be.blank
    @member.avatar.visitor_id.should.be.blank
  end
  
  it "should still allow to bypass validations on the associated model" do
    @member.email = ''
    @member.avatar.name = ''
    
    @member.save(false).should.be true
    @member.reload
    
    @member.email.should.be.blank
    @member.avatar.name.should.be.blank
  end
  
  it "should still raise an ActiveRecord::RecordInvalid exception if we want that" do
    @member.avatar.name = ''
    
    lambda {
      @member.save!
    }.should.raise(ActiveRecord::RecordInvalid)
  end
  
end

describe "AutosaveAssociation, on a has_many association" do
  before do
    setup_db
    
    @visitor = Visitor.create(:email => 'paco@example.com')
    @avatar1 = @visitor.avatars.create(:name => 'smiley1')
    @avatar2 = @visitor.avatars.create(:name => 'smiley2')
  end
  
  after do
    teardown_db
  end
  
  it "should still work as normal" do
    @visitor.attributes = { :email => 'pablo@example.com' }
    @visitor.email.should == 'pablo@example.com'
  end
  
  it "should automatically save the associated models" do
    @avatar1.name = 'sadly1'
    @avatar2.name = 'sadly2'
    @visitor.save!; @visitor.reload
    
    @visitor.avatars.map(&:name).sort.should == %w{ sadly1 sadly2 }
  end
  
  it "should automatically validate the associated models" do
    @visitor.avatars.first.name = ''
    @visitor.avatars.last.name = ''
    
    @visitor.should.not.be.valid
    @visitor.errors.on(:avatars_name).should == "can't be blank"
    @visitor.errors.on(:avatars).should.be.blank
  end
  
  it "should rollback any changes if an exception occurred while saving" do
    @visitor.avatars.first.stubs(:save).raises(RuntimeError, 'Error!')
    
    @visitor.avatars.last.member_id = 123
    @visitor.address = 'Another address 1'
    
    lambda {
      @visitor.save.should.be false
    }.should.not.raise(Exception)
    
    @visitor.reload
    @visitor.address.should.be.blank
    @visitor.avatars.last.member_id.should.be.blank
  end
  
  it "should still allow to bypass validations on the associated models" do
    @visitor.email = ''
    @visitor.avatars.first.name = ''
    
    @visitor.save(false).should.be true
    @visitor.reload
    
    @visitor.email.should.be.blank
    @visitor.avatars.first.name.should.be.blank
  end
  
  it "should still raise an ActiveRecord::RecordInvalid exception if we want that" do
    @visitor.avatars.first.name = ''
    
    lambda {
      @visitor.save!
    }.should.raise(ActiveRecord::RecordInvalid)
  end
end