class FakeProfile < ActiveRecord::Base
  
  #attr_accessor :first_name, :last_name, :bio, :age

  belongs_to :fake_user
  
  solr_searchable :fields => [
    {:text => :first_name},
    {:text => :last_name},
    {:text => :bio},
    {:string => :age}
  ]
  
  # def first_name
  #   "Cody"
  # end
  # 
  # def last_name
  #   "Caughlan"
  # end
  # 
  # def bio
  #   "I am you!"
  # end
  # 
  # def age
  #   30
  # end
  
  #def id
  #  93
  #end
  
end

class FakeUser < ActiveRecord::Base
  has_one :fake_profile
end