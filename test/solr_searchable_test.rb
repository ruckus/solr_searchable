require File.dirname(__FILE__) +  '/test_helper'
require File.dirname(__FILE__) +  '/schema'

$:.unshift(File.dirname(__FILE__) + '/fixtures')
require 'models'

class SolrSearchableTest < ActiveSupport::TestCase
  
  # test "add document" do
  #   add_document
  # end
  # 
  # test "delete document" do
  #   add_document
  #   p = FakeProfile.first
  #   p.destroy
  # end
  # 
  # test "solr ping" do
  #   add_document
  #   p = FakeProfile.first
  #   assert p.solr_alive?
  # end
  # 
  # test "search solr" do
  #   add_document
  #   q = "first_name_t:Marcus"
  #   data = FakeProfile.find_by_solr(q)
  #   puts data.inspect
  # end
  
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
    puts c.to_s
  end  
  
  private
  
  def add_document
    p = FakeProfile.new
    p.to_solr_doc
    p.first_name = "Marcus"
    p.last_name = "Holt"
    p.bio = "A small boy from Minnesota..."
    p.save
  end
  
end























