require 'rails_helper'

RSpec.describe Account, type: :model do
  describe 'email format validation' do
    it 'is valid with a properly formatted email' do
      account = Account.new(email: 'user@example.com')
      expect(account).to be_valid
    end

    it 'is invalid when email contains a space' do
      account = Account.new(email: 'user @example.com')
      expect(account).not_to be_valid
      expect(account.errors[:email]).to be_present
    end

    it 'is invalid when email is missing the @ symbol' do
      account = Account.new(email: 'userexample.com')
      expect(account).not_to be_valid
      expect(account.errors[:email]).to be_present
    end
  end
end
