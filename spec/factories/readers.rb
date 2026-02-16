FactoryBot.define do
  factory :reader do
    sequence(:serial_number) { |n| (100_000 + n).to_s }
    email { Faker::Internet.unique.email }
    full_name { Faker::Name.name }
  end
end
