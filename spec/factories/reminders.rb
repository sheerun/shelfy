FactoryBot.define do
  factory :reminder do
    book_borrow
    reminder_type { "3_days_warning" }
    scheduled_for { book_borrow.due_date - 3.days }
    sent_at { nil }

    trait :due_date_alert do
      reminder_type { "due_date_alert" }
      scheduled_for { book_borrow.due_date }
    end

    trait :sent do
      sent_at { Time.current }
    end
  end
end
