require 'rails_helper'

RSpec.describe Permission, type: :model do
  describe 'uniqueness validation' do
    let(:user) { create(:user, name: 'John Doe') }
    let(:group) { Group.create!(name: 'Developers') }
    let(:asset) { create(:task) }

    before do
      Audit::Request.whodunnit = user.id
    end

    after do
      Audit::Request.whodunnit = nil
    end

    let!(:existing_permission) do
      Permission.create!(
        user: user,
        group: group,
        asset: asset,
        action: 'all'
      )
    end

    it 'is invalid when the same user, group, and asset combination already exists' do
      duplicate = Permission.new(
        user: user,
        group: group,
        asset: asset,
        action: 'all'
      )
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to be_present
    end

    it 'is valid with a different user' do
      other_user = create(:user)
      permission = Permission.new(
        user: other_user,
        group: group,
        asset: asset,
        action: 'all'
      )
      expect(permission).to be_valid
    end

    it 'is valid with a different group' do
      other_group = Group.create!(name: 'Managers')
      permission = Permission.new(
        user: user,
        group: other_group,
        asset: asset,
        action: 'all'
      )
      expect(permission).to be_valid
    end

    it 'is valid with a different asset' do
      other_asset = create(:task)
      permission = Permission.new(
        user: user,
        group: group,
        asset: other_asset,
        action: 'all'
      )
      expect(permission).to be_valid
    end
  end
end
