require 'rails_helper'

RSpec.describe Ability, type: :model do
  subject(:ability) { described_class.new(user) }

  let(:user) { create(:user) }

  describe 'initialization' do
    it 'includes CanCan methods' do
      expect(ability).to respond_to(:can?, :cannot?, :can, :cannot)
    end
  end

  describe 'User permissions' do
    it 'can manage their own record' do
      expect(ability).to be_able_to(:manage, user)
    end
    
    it 'cannot manage another user' do
      other_user = create(:user)
      expect(ability).not_to be_able_to(:manage, other_user)
    end
  end

  describe 'Task permissions' do
    it 'can create a Task' do
      expect(ability).to be_able_to(:create, Task)
    end

    context 'when task belongs to user' do
      let(:task) { build(:task, user: user) }

      it 'can manage it' do
        expect(ability).to be_able_to(:manage, task)
      end
    end

    context 'when task belongs to another user' do
      let(:other_user) { create(:user) }
      let(:task) { build(:task, user: other_user) }

      it 'cannot manage it' do
        expect(ability).not_to be_able_to(:manage, task)
      end
    end

    context 'when task is assigned to user' do
      let(:task) { build(:task, assignee_id: user.id) }

      it 'can manage it' do
        expect(ability).to be_able_to(:manage, task)
      end
    end

    context 'when task is assigned to another user' do
      let(:other_user) { create(:user) }
      let(:task) { build(:task, assignee_id: other_user.id) }

      it 'cannot manage it' do
        expect(ability).not_to be_able_to(:manage, task)
      end
    end
  end

  describe 'Entity permissions' do
    context 'with Account' do
      it 'can manage a public account' do
        account = build(:account, access: 'Public', assignee_id: nil, user_id: nil)
        expect(ability).to be_able_to(:manage, account)
      end

      it 'cannot manage a private account they do not own or are not assigned to' do
        account = build(:account, access: 'Private')
        expect(ability).not_to be_able_to(:manage, account)
      end

      it 'can manage an account assigned to them' do
        account = build(:account, assignee_id: user.id)
        expect(ability).to be_able_to(:manage, account)
      end

      it 'cannot manage an account assigned to another user' do
        other_user = create(:user)
        account = build(:account, assignee_id: other_user.id)
        expect(ability).not_to be_able_to(:manage, account)
      end
    end
  end
end
