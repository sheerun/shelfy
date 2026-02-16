FactoryBot.define do
  factory :book do
    sequence(:serial_number) { |n| (100_000 + n).to_s }
    title { "#{Faker::Book.title} #{SecureRandom.hex(4)}" }
    author { Faker::Book.author }
  end
end
