require File.expand_path('../test_helper', __FILE__)

describe "NestedParams, on a has_many association" do
  before do
    setup_db
    
    @visitor = Visitor.create(:email => 'paco@example.com')
    @artist1 = @visitor.artists.create(:name => 'paco')
    @artist2 = @visitor.artists.create(:name => 'poncho')
  end
  
  after do
    teardown_db
  end
  
  it "should still work as normal" do
    @visitor.artists = [@artist1]
    @visitor.save!; @visitor.reload
    @visitor.artists.should == [@artist1]
  end
  
  it "should take a hash and assign the attributes to the associated models" do
    @visitor.attributes = {
      :artists => {
        @artist1.id.to_s => { :name => 'joe' },
        @artist2.id.to_s => { :name => 'jack' }
      }
    }
    
    @visitor.artists.map(&:name).sort.should == %w{ jack joe }
  end
  
  it "should automatically enable autosave on the association" do
    @visitor.attributes = {
      :artists => {
        @artist1.id.to_s => { :name => 'joe' },
        @artist2.id.to_s => { :name => 'jack' }
      }
    }
    @visitor.save!; @visitor.reload
    
    @visitor.artists.map(&:name).sort.should == %w{ jack joe }
  end
  
  it "should automatically build a new associated model if there is none" do
    @visitor.artists.destroy_all; @visitor.reload
    @visitor.attributes = { :artists => [{ :name => 'Pablo' }, { :name => 'Paco' }] }
    
    @visitor.artists.first.should.be.new_record
    @visitor.artists.first.name.should == 'Pablo'
    
    @visitor.artists.last.should.be.new_record
    @visitor.artists.last.name.should == 'Paco'
  end
  
  it "should work with update_attributes as well" do
    @visitor.update_attributes({
      :artists => {
        @artist1.id.to_s => { :name => 'joe' },
        @artist2.id.to_s => { :name => 'jack' }
      }
    })
    @visitor.reload
    @visitor.artists.map(&:name).sort.should == %w{ jack joe }
  end
  
  it "should update existing records and add new ones that have an id that start with the string 'new_'" do
    before = Artist.count
    
    @visitor.update_attributes({
      :artists => {
        @artist1.id.to_s => { :name => 'joe' },
        "new_12345" => { :name => 'jill' },
        @artist2.id.to_s => { :name => 'jack' }
      }
    })
    @visitor.reload
    
    Artist.count.should.be before + 1
    @visitor.artists.map(&:name).sort.should == %w{ jack jill joe }
  end
end

describe "NestedParams, on a has_one association" do
  before do
    setup_db
    
    @member = Member.create(:email => 'paco@example.com')
    @artist = @member.create_artist(:name => 'Mister Paco')
  end
  
  after do
    teardown_db
  end
  
  it "should still work as normal" do
    @member.artist = Artist.new(:name => 'Poncho')
    @member.artist.name.should == 'Poncho'
  end
  
  it "should take a hash and assign the attributes to the associated model" do
    @member.attributes = { :email => 'pablo@example.com', :artist => { :name => 'Pablo' } }
    @member.email.should == 'pablo@example.com'
    @member.artist.name.should == 'Pablo'
  end
  
  it "should also work with a HashWithIndifferentAccess" do
    @member.attributes = HashWithIndifferentAccess.new(:email => 'pablo@example.com', :artist => HashWithIndifferentAccess.new(:name => 'Pablo'))
    @member.email.should == 'pablo@example.com'
    @member.artist.name.should == 'Pablo'
  end
  
  it "should work with update_attributes as well" do
    @member.update_attributes({ :email => 'pablo@example.com', :artist => { :name => 'Pablo' } })
    @member.reload
    @member.artist.name.should == 'Pablo'
  end
  
  it "should automatically instantiate an associated model if there is none" do
    @artist.destroy; @member.reload
    @member.attributes = { :artist => { :name => 'Pablo' } }
    
    @member.artist.should.be.new_record
    @member.artist.name.should == 'Pablo'
  end
  
  it "should automatically extend the model class with the AutosaveAssociation module" do
    klass = Class.new do
      class << self
        def has_one(*args); end
        def has_many(*args); end
      end
      
      extend NestedParams
    end
    (class << klass; self; end).should.include AutosaveAssociation
  end
  
  it "should automatically enable autosave on the association" do
    @member.attributes = { :email => 'pablo@example.com', :artist => { :name => 'Pablo' } }
    @member.save!; @member.reload
    @member.artist.name.should == 'Pablo'
  end
  
  it "should automatically validate the associated model" do
    @member.artist.name = ''
    @member.should.not.be.valid
    @member.errors.on(:name).should.not.be.blank
  end
end