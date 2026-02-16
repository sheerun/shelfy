module Library
  class SendReminderJob < ApplicationJob
    queue_as :default

    def perform(reminder_id)
      Library::SendReminder.new(reminder_id: reminder_id).execute
    end
  end
end
