class UserMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.verify_email.subject
  #
  def verify_email
    @greeting = "Hi"

    mail to: "to@example.org"
  end

  def confirmation_instructions(user, token, *args, **kwargs)
    @user = user
    @token = token

    mail(to: @user.email, subject: "Please confirm your email address")
   end
end
