require File.expand_path('../test_helper', __FILE__)

require 'action_controller'
require 'action_controller/test_process'
require 'action_view/test_case'

require 'nested_params_form_builder'

class NestedParamsFormBuilderTest < ActionView::TestCase
  tests ActionView::Helpers::FormHelper
  
  def setup
    @controller = Class.new do
      attr_reader :url_for_options
      def url_for(options)
        @url_for_options = options
        "http://www.example.com"
      end
    end
    @controller = @controller.new
    
    setup_db
    @visitor = Visitor.create(:email => 'paco@example.com')
  end
  
  def teardown
    teardown_db
  end
  
  def test_should_build_a_form_for_existing_records
    @visitor.artists.create(:name => 'paco')
    @visitor.artists.create(:name => 'poncho')
    
    _erbout = ''
    
    form_for(:visitor, @visitor, :builder => NestedParamsFormBuilder) do |vf|
      @visitor.artists.each do |artist|
        vf.fields_for(:artists, artist) do |af|
          _erbout.concat af.text_field(:name)
        end
      end
    end
    
    expected = '<form action="http://www.example.com" method="post">' +
               '<input id="visitor_artists_attributes__1_name" name="visitor[artists_attributes][1][name]" size="30" type="text" value="paco" />' +
               '<input id="visitor_artists_attributes__2_name" name="visitor[artists_attributes][2][name]" size="30" type="text" value="poncho" />' +
               '</form>'
    
    assert_dom_equal expected, _erbout
  end
  
  def test_should_build_a_form_for_new_records_using_a_incremental_counter_as_a_composited_id
    paco = @visitor.artists.build(:name => 'paco')
    poncho = @visitor.artists.build(:name => 'poncho')
    
    _erbout = ''
    
    form_for(:visitor, @visitor, :builder => NestedParamsFormBuilder) do |vf|
      @visitor.artists.each do |artist|
        vf.fields_for(:artists, artist) do |af|
          _erbout.concat af.text_field(:name)
        end
      end
    end
    
    expected = '<form action="http://www.example.com" method="post">' +
               "<input id=\"visitor_artists_attributes__new_1_name\" name=\"visitor[artists_attributes][new_1][name]\" size=\"30\" type=\"text\" value=\"paco\" />" +
               "<input id=\"visitor_artists_attributes__new_2_name\" name=\"visitor[artists_attributes][new_2][name]\" size=\"30\" type=\"text\" value=\"poncho\" />" +
               '</form>'
    
    assert_dom_equal expected, _erbout
  end
  
  def test_should_build_a_form_for_existing_and_new_records
    @visitor.artists.create(:name => 'paco')
    poncho = @visitor.artists.build(:name => 'poncho')
    
    _erbout = ''
    
    form_for(:visitor, @visitor, :builder => NestedParamsFormBuilder) do |vf|
      @visitor.artists.each do |artist|
        vf.fields_for(:artists, artist) do |af|
          _erbout.concat af.text_field(:name)
        end
      end
    end
    
    expected = '<form action="http://www.example.com" method="post">' +
               '<input id="visitor_artists_attributes__1_name" name="visitor[artists_attributes][1][name]" size="30" type="text" value="paco" />' +
               "<input id=\"visitor_artists_attributes__new_1_name\" name=\"visitor[artists_attributes][new_1][name]\" size=\"30\" type=\"text\" value=\"poncho\" />" +
               '</form>'
    
    assert_dom_equal expected, _erbout
  end
  
  private
  
  def protect_against_forgery?
    false
  end
end