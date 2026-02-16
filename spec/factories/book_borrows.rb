FactoryBot.define do
  factory :book_borrow do
    book
    reader
    borrow_date { Date.current }
    due_date { Date.current + BookBorrow::LOAN_PERIOD_DAYS.days }
    return_date { nil }

    trait :returned do
      return_date { Date.current }
    end

    trait :overdue do
      borrow_date { 60.days.ago.to_date }
      due_date { 30.days.ago.to_date }
    end
  end
end
