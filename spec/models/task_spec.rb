require 'rails_helper'

RSpec.describe Task, type: :model do
  describe 'ransack' do
    it 'exposes the .ransack search method on the model' do
      expect(Task.ransack(name_cont: 'anything')).to be_a(Ransack::Search)
    end
  end
end
