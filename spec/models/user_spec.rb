require 'rails_helper'

RSpec.describe User, type: :model do
  describe '#admin?' do
    let(:user) { create(:user) }
    let(:admin_role) { Role.create!(name: "admin") }

    it 'returns true when user has admin role' do
      user.roles << admin_role
      expect(user.admin?).to be true
    end

    it 'returns false when user does not have admin role' do
      expect(user.admin?).to be false
    end
  end
end
