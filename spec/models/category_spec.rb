require 'rails_helper'

describe Category, type: :model do
  let(:category) { FactoryGirl.create(:category) }

  context 'with no runs' do
    it 'destroys itself when asked if empty' do
      category.destroy_if_empty
      expect(category.destroyed?).to eq(true)
    end
  end

  context 'with runs' do
    it 'does not destroy itself when asked if empty' do
      FactoryGirl.create(:run, category: category)
      category.destroy_if_empty
      expect(category.destroyed?).to eq(false)
    end
  end
end
