require 'rails_helper'

RSpec.describe Account, type: :model do
  describe '#permissions' do
    let(:user)    { create(:user) }
    let(:group)   { Group.create!(name: 'Editors') }
    let(:account) { Account.create!(email: 'test@example.com') }

    before { Audit::Request.whodunnit = user.id }
    after  { Audit::Request.whodunnit = nil }

    it 'returns permissions where asset_type is Account and asset_id matches' do
      permission = Permission.create!(user: user, group: group, asset: account, action: 'all')
      expect(account.permissions).to contain_exactly(permission)
    end

    it 'does not return permissions belonging to a different account' do
      other = Account.create!(email: 'other@example.com')
      Permission.create!(user: user, group: group, asset: other, action: 'all')
      expect(account.permissions).to be_empty
    end
  end

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
