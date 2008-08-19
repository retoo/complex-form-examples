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
end