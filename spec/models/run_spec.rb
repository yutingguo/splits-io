require 'rails_helper'

describe Run, type: :model do
  let(:run) { FactoryGirl.create(:run) }

  it 'responds to base 36 id requests' do
    expect(run.id36).to eq(run.id.to_s(36))
  end

  context 'with a valid video URL to a non-valid location' do
    let(:run) { FactoryGirl.build(:run, video_url: 'http://google.com/') }

    it 'fails to validate' do
      expect(run).not_to be_valid
    end
  end

  context 'with an invalid video URL' do
    let(:run) { FactoryGirl.build(:run, video_url: 'Huge improvement. That King Boo fight tho... :/ 4 HP strats!') }

    it 'fails to validate' do
      expect(run).not_to be_valid
    end
  end

  context 'that is new' do
    it 'has a non-nil claim token' do
      expect(run.claim_token).not_to eq(nil)
    end
  end

  context 'that is the last in its category' do
    let(:category) { FactoryGirl.create(:category) }
    let(:another_category) { FactoryGirl.create(:category) }
    let(:run) { FactoryGirl.create(:run, category: category) }

    it 'destroys its category when destroyed' do
      run.destroy
      expect(category.destroyed?).to eq(true)
    end

    it 'destroys its old category when saving a category change with Run#category=' do
      puts 'this one'
      run.category = another_category
      run.save
      expect(category.destroyed?).to eq(true)
    end

    it 'destroys its old category when saving a category change with Run#update' do
      run.update(category: FactoryGirl.create(:category))
      expect(category.destroyed?).to eq(true)
    end

    it 'does not destroy its old category when its category attribute changes' do
      run.category = FactoryGirl.create(:category)
      expect(category.destroyed?).to eq(false)
    end
  end

  context 'that is not the last in its category' do
    let(:category) { FactoryGirl.create(:category) }
    let(:run) { FactoryGirl.create(:run, category: category) }
    let(:sibling_run) { FactoryGirl.create(:run, category: category) }

    it 'does not destroy its category when destroyed' do
      run.category = FactoryGirl.create(:category)
      expect(category.destroyed?).to eq(false)
    end

    it 'does not destroy its old category when saving a category change' do
      run.category = FactoryGirl.create(:category)
      run.save
      expect(category.destroyed?).to eq(false)
    end

    it 'does not destroy its old category when its category attribute changes' do
      run.category = FactoryGirl.create(:category)
      expect(category.destroyed?).to eq(false)
    end
  end

  context 'without a category' do
    let(:run) { FactoryGirl.create(:run, category: nil) }

    it 'does not error when destroyed' do
      run.destroy
      expect(run.destroyed?).to eq(true)
    end

    it 'does not error when changing categories' do
      run.category = FactoryGirl.create(:category)
      expect(run.save).to eq(true)
    end
  end

  context 'with a category' do
    let(:run) { FactoryGirl.create(:run, category: FactoryGirl.build(:category)) }

    it 'is destroyed when asked' do
      run.destroy
      expect(run.destroyed?).to eq(true)
    end

    it 'does not error when changing categories' do
      run.category = FactoryGirl.create(:category)
      expect(run.save).to eq(true)
    end

    it 'does not error when clearing category' do
      run.category = nil
      expect(run.save).to eq(true)
    end
  end
end
