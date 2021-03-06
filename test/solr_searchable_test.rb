require File.dirname(__FILE__) +  '/test_helper'
require File.dirname(__FILE__) +  '/schema'

$:.unshift(File.dirname(__FILE__) + '/fixtures')
require 'models'

class SolrSearchableTest < ActiveSupport::TestCase
  
  def teardown
    FakeProfile.delete_by_query('type_s:FakeProfile')
    FakeProfile.solr_commit
  end
  
  test "add document" do
    add_document
  end
  
  test "delete document" do
    add_document(attrs = {:first_name => "Marcus", :last_name => "Holt", :bio => "A small boy from Minnesota..."})
    p = FakeProfile.first
    p.destroy
  end
  
  test "solr ping" do
    add_document(attrs = {:first_name => "Marcus", :last_name => "Holt", :bio => "A small boy from Minnesota..."})
    p = FakeProfile.first
    assert p.solr_alive?
  end
  
  test "search solr" do
    first_name = 'Marcus'
    add_document(attrs = {:first_name => first_name, :last_name => "Holt", :bio => "A small boy from Minnesota..."})
    q = "first_name_t:Marcus"
    data = FakeProfile.find_by_solr(q)
    #puts data.inspect
    assert_not_nil data[:docs]
    assert_equal(data[:docs].first.first_name, first_name)
  end
  
  test "query building" do
    c = SolrSearchable::Clause.new(FakeProfile)
    c1 = SolrSearchable::Clause.new(FakeProfile)
    c2 = SolrSearchable::Clause.new(FakeProfile)

    #c.and(:first_name => "cody head").and(:bio => "aaaa")    
    #c.or({:last_name => ["caughlan", 100]})
    #c.and({:last_name => ["caughlan", 100]})
    
    #c2.or({:last_name => ["caughlan", 100], :bio => "bbbbbbbbb"})
    #puts "C2: #{c2}"
    #c.and(c2, :last_name => 'koga')
    #c2.or(:last_name => 'koga', :first_name => 'micah')
    
    c1.and(:first_name => 'cody chestnut', :last_name => 'micah')
    c2.or(:age => 30, :bio => 'green')
    c.or(c1)
    c.or(c2)
    #(f1:cody AND l2:micah) OR (age:30 AND house:green)
    
    
    #c << [{:bio => "fluffy dragon", :first_name => "cody"}, :OR]
    #c.raw({:bio => "is the best", :first_name => "cody"}, :OR)
    #c << {:bio => "is the best", :OR}
    #puts c.to_s
  end  
  
  test "can eager load an ActiveRecord model" do
    attrs = {:first_name => "Marcus", :last_name => "Holt", :bio => "A small boy from Minnesota..."}    
    profile = add_document(attrs)
    user = FakeUser.create(:email => "marcus@example.com")
    profile.fake_user_id = user.id
    profile.save
    assert_not_nil profile
    assert_not_nil user
    # commit it all to solr
    FakeProfile.solr_commit
    clause = SolrSearchable::Clause.new(FakeProfile)
    clause.and(:first_name => "Marcus")
    results = FakeProfile.find_by_solr(clause.to_s, :include => [:fake_user])
    assert_not_nil results
  end
  
  test "can count by solr" do
    attrs = {:first_name => "Marcus", :last_name => "Holt", :bio => "A small boy from Minnesota..."}    
    profile = add_document(attrs)
    clause = SolrSearchable::Clause.new(FakeProfile)
    clause.and(:first_name => "Marcus")
    count = FakeProfile.count_by_solr(clause.to_s)
    assert_equal(1, count)
  end
  
  private
  
  def add_document(attributes = {})
    p = FakeProfile.new(attributes)
    p.save
    #puts p.to_solr_doc.inspect
    p
  end
  
end























