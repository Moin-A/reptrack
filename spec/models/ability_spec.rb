require 'rails_helper'

RSpec.describe Ability, type: :model do
  let(:user) { User.new }

  describe 'initialization' do
    it 'includes CanCan methods' do
      ability = described_class.new(user)
      expect(ability).to respond_to(:can?, :cannot?, :can, :cannot)
    end
  end
end
