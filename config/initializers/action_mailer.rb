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

# Monkey patch to allow sending of messages in specific locales
module ActionMailer
  class Base
    def mail_with_locale(*args)
      old_locale = I18n.locale

      begin
        I18n.locale = @locale
        message = mail_without_locale(*args)
      ensure
        I18n.locale = old_locale
      end

      message
    end

    alias_method_chain :mail, :locale
  end
end
