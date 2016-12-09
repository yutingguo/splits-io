require 'speedrunslive'

class Game < ApplicationRecord
  include SRLGame

  validates :name, presence: true

  has_many :categories
  has_many :runs, through: :categories
  has_many :aliases, class_name: 'Game::Alias'

  after_create :create_initial_alias

  scope :named, -> { where.not(name: nil) }
  scope :shortnamed, -> { where.not(shortname: nil) }

  def self.search(term)
    term = term.strip
    return nil if term.blank?
    joins(:aliases).where('game_aliases.name LIKE ? OR games.shortname LIKE ?', "%#{term}%", "%#{term}%").distinct
  end

  def self.from_name(name)
    name = name.strip
    return nil if name.blank?
    joins(:aliases).where(game_aliases: {name: name}).first
  end

  def self.from_name!(name)
    name = name.strip
    return nil if name.blank?
    joins(:aliases).where(game_aliases: {name: name}).first_or_create(name: name)
  end

  def to_param
    shortname || id.to_s || name.downcase.gsub('/', '')
  end

  def sync_with_srl
    return if shortname.present?
    game = ::SpeedRunsLive.game(name)
    return if game.nil?

    update(shortname: game['abbrev'])
  end

  def to_s
    name
  end

  def popular_categories
    categories.joins(:runs).group('categories.id').having('count(runs.id) >= ' + (Run.where(category: categories.pluck(:id)).count / 20).to_s).order('count(runs.id) desc')
  end

  def unpopular_categories
    categories.joins(:runs).group('categories.id').having('count(runs.id) < ' + (Run.where(category: categories.pluck(:id)).count / 20).to_s).order('count(runs.id) desc')
  end

  # merge_into! changes ownership of all of this game's categories and aliases to the given game, then destroys this
  # game.
  def merge_into!(game)
    ApplicationRecord.transaction do
      aliases.update_all(game_id: game.id)

      categories.each do |category|
        equivalent_category = game.categories.find_by(name: category.name)

        if equivalent_category.present?
          category.merge_into!(equivalent_category)
        else
          category.update(game: game)
        end
      end
      destroy
    end
  end

  def permalink_redirectors?
    key = {game_id: "#{id}"}
    attrs = 'game_id'

    options = {
      key: key,
      projection_expression: attrs
    }

    resp = $dynamodb_games_with_permalink_redirectors.get_item(options)

    if resp.item.nil?
      return false
    end

    return true
  end

  def enable_permalink_redirectors
    game = {
      'game_id' => "#{id}",
      'has_permalink_redirectors' => true,

      'created_at' => created_at.to_i,
      'updated_at' => Time.now.to_i
    }

    $dynamodb_games.put_item(item: game)
  end

  def disable_permalink_redirectors
    game = {
      'game_id' => "#{id}",
      'has_permalink_redirectors' => false,

      'created_at' => created_at.to_i,
      'updated_at' => Time.now.to_i
    }

    $dynamodb_games.put_item(item: game)
  end

  private

  def create_initial_alias
    aliases.create(name: name)
  end
end
