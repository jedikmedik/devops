FactoryBot.define do
  factory :paste do
    body Faker::Book.title
    request_info Faker::Book.title
    language 'text'
    ttl_days (0..90).to_a.sample
  end
end
