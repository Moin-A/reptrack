require 'rails_helper'

RSpec.describe Account, type: :model do
  describe '#permissions' do
    let(:user)    { create(:user) }
    let(:group)   { Group.create!(name: 'Editors') }
    let(:account) { Account.create!(email: 'test@example.com', name: 'Test Account') }

    before { Audit::Request.whodunnit = user.id }
    after  { Audit::Request.whodunnit = nil }

    it 'returns permissions where asset_type is Account and asset_id matches' do
      permission = Permission.create!(user: user, group: group, asset: account, action: 'all')
      expect(account.permissions).to contain_exactly(permission)
    end

    it 'does not return permissions belonging to a different account' do
      other = Account.create!(email: 'other@example.com', name: 'Other Account')
      Permission.create!(user: user, group: group, asset: other, action: 'all')
      expect(account.permissions).to be_empty
    end
  end

  describe '#user_ids=' do
    let(:group)   { Group.create!(name: 'Test Group') }
    let(:account) { Account.create!(email: 'test@example.com', name: 'Test Account') }
    let(:user1)   { create(:user) }
    let(:user2)   { create(:user) }
    let(:user3)   { create(:user) }
    let(:outsider) { create(:user) }

    before { Audit::Request.whodunnit = user1.id }
    after  { Audit::Request.whodunnit = nil }

    it 'removes permissions whose user_id is not in the given list' do
      Permission.create!(user: outsider, group: group, asset: account, action: 'all')
      account.user_ids = [ user1.id, user2.id, user3.id ]
      expect(account.permissions.map(&:user_id)).not_to include(outsider.id)
    end

    it 'retains permissions whose user_id is in the given list' do
      account.update(access: 'Shared')
      kept = Permission.create!(user: user1, group: group, asset: account, action: 'all')
      Permission.create!(user: outsider, group: group, asset: account, action: 'all')
      account.user_ids = [ user1.id ]
      expect(Permission.exists?(kept.id)).to be true
    end

    it 'leaves only permissions matching the given user_ids' do
      account.update(access: 'Shared')
      Permission.create!(user: user1,   group: group, asset: account, action: 'all')
      Permission.create!(user: user2,   group: group, asset: account, action: 'all')
      Permission.create!(user: outsider, group: group, asset: account, action: 'all')
      account.user_ids = [ user1.id, user2.id ]
      expect(account.permissions.map(&:user_id)).to match_array([ user1.id, user2.id ])
    end

    it 'deletes all permissions when access is Private, regardless of given ids' do
      account.update(access: 'Private')
      Permission.create!(user: user1, group: group, asset: account, action: 'all')
      Permission.create!(user: user2, group: group, asset: account, action: 'all')
      account.user_ids = [ user1.id, user2.id ]
      expect(account.permissions).to be_empty
    end

    it 'deletes all permissions when access is Public, regardless of given ids' do
      account.update(access: 'Public')
      Permission.create!(user: user1, group: group, asset: account, action: 'all')
      Permission.create!(user: user2, group: group, asset: account, action: 'all')
      account.user_ids = [ user1.id, user2.id ]
      expect(account.permissions).to be_empty
    end
  end

  describe '#group_ids=' do
    let(:user)    { create(:user) }
    let(:account) { Account.create!(email: 'group_test@example.com', name: 'Group Test Account') }
    let(:group1)  { Group.create!(name: 'Group One') }
    let(:group2)  { Group.create!(name: 'Group Two') }

    before { Audit::Request.whodunnit = user.id }
    after  { Audit::Request.whodunnit = nil }

    context 'when access is not Shared' do
      it 'deletes all permissions when access is Private, regardless of given ids' do
        account.update(access: 'Private')
        Permission.create!(user: user, group: group1, asset: account, action: 'all')
        Permission.create!(user: user, group: group2, asset: account, action: 'all')
        account.group_ids = [ group1.id, group2.id ]
        expect(account.permissions).to be_empty
      end

      it 'deletes all permissions when access is Public, regardless of given ids' do
        account.update(access: 'Public')
        Permission.create!(user: user, group: group1, asset: account, action: 'all')
        Permission.create!(user: user, group: group2, asset: account, action: 'all')
        account.group_ids = [ group1.id, group2.id ]
        expect(account.permissions).to be_empty
      end
    end
  end

  describe 'email format validation' do
    it 'is valid with a properly formatted email' do
      account = Account.new(email: 'user@example.com', name: 'Test Account')
      expect(account).to be_valid
    end

    it 'is invalid when email contains a space' do
      account = Account.new(email: 'user @example.com', name: 'Test Account')
      expect(account).not_to be_valid
      expect(account.errors[:email]).to be_present
    end

    it 'is invalid when email is missing the @ symbol' do
      account = Account.new(email: 'userexample.com', name: 'Test Account')
      expect(account).not_to be_valid
      expect(account.errors[:email]).to be_present
    end
  end
end
