ActiveRecord::Schema.define(:version => 0) do

  create_table :fake_profiles, :force => true do |t|
    t.integer :fake_user_id
    t.string :first_name
    t.string :last_name
    t.text   :bio
    t.integer :age
    t.datetime :pub_date
    t.datetime :created_at
    t.datetime :updated_at
  end
  
  create_table :fake_users, :force => true do |t|
    t.string :email
  end
  
end
