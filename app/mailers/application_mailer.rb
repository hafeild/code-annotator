class ApplicationMailer < ActionMailer::Base
  default from: ENV['FROM_EMAIL'], reply_to: ENV['REPLY_TO_EMAIL']
  layout 'mailer'
end
