# Configure ActionMailer SMTP settings
ActionMailer::Base.smtp_settings = {
  :address => MAIL_SERVER,
  :port => 587,
  :domain => MAIL_SERVER,
  :user_name => MAIL_USERNAME,
  :password => MAIL_PASSWORD,
  :authentication => 'plain',
  :enable_starttls_auto => true
}
