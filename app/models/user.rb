class User < ApplicationRecord
  include AuthenticatingUser
  include RivalUser
  include TwitchUser

  has_many :runs
  has_many :categories, -> { distinct }, through: :runs
  has_many :games, -> { distinct }, through: :runs
  has_many :rivalries, foreign_key: :from_user_id, dependent: :destroy
  has_many :incoming_rivalries, class_name: Rivalry, foreign_key: :to_user_id, dependent: :destroy
  has_many :subscriptions

  after_destroy do |user|
    user.runs.update_all(user_id: nil)
  end

  validates :twitch_id, presence: true
  validates :name, presence: true

  scope :with_runs, -> { joins(:runs).distinct }
  scope :that_run, ->(category) { joins(:runs).where(runs: {category: category}).distinct }

  def self.search(term)
    where(User.arel_table[:name].matches "%#{term}%").joins(:runs).uniq.order(:name)
  end

  def avatar
    if read_attribute(:avatar).nil?
      return nil
    end

    URI.parse(read_attribute(:avatar) || '').tap do |uri|
      uri.scheme = 'https'
    end.to_s
  end

  def uri
    URI::parse("http://www.twitch.tv/#{name}")
  end

  def to_param
    name
  end

  def pb_for(category)
    runs.where(category: category).order(:time).first
  end

  def pbs
    runs.where(
      id: categories.map { |category| pb_for(category).id10 } | runs.where(category: nil).pluck(:id)
    )
  end

  def runs?(category)
    runs.where(category: category).present?
  end

  def to_s
    name || 'somebody'
  end

  def darkmode
    false
  end

  def gold?
    permagold? || subscriptions.count > 0 || silver_patron?
  end

  def should_see_ads?
    !bronze_patron?
  end

  def patreon_info
    key = {user_id: "#{id}"}
    attrs = 'id, patreon_full_name, pledge_cents'

    options = {
      key: key,
      projection_expression: attrs
    }

    resp = $dynamodb_patreon_users.get_item(options)

    if resp.item.nil?
      return nil
    end

    return resp.item
  end

  def bronze_patron?
    p = patreon_info
    if p.nil?
      return false
    end

    if p['pledge_cents'].nil?
      return false
    end

    p['pledge_cents'] >= 200
  end

  def silver_patron?
    p = patreon_info
    if p.nil?
      return false
    end

    if p['pledge_cents'].nil?
      return false
    end

    p['pledge_cents'] >= 400
  end

  def gold_patron?
    p = patreon_info
    if p.nil?
      return false
    end

    if p['pledge_cents'].nil?
      return false
    end

    p['pledge_cents'] >= 600
  end

  def team_player_patron?
    p = patreon_info
    if p.nil?
      return false
    end

    if p['pledge_cents'].nil?
      return false
    end

    p['pledge_cents'] >= 1000
  end

  def community_member_patron?
    p = patreon_info
    if p.nil?
      return false
    end

    if p['pledge_cents'].nil?
      return false
    end

    p['pledge_cents'] >= 1200
  end

  def permalink_redirectors?
    gold_patron? || teammate_is_gold_patron?
  end

  def teammate_is_gold_patron?
    key = {user_id: "#{id}"}
    attrs = 'user_id'

    options = {
      key: key,
      projection_expression: attrs
    }

    resp = $dynamodb_user_teams.get_item(options)

    if resp.item.nil?
      return false
    end

    return true
  end

  def gold_patron_teammate
    key = {user_id: "#{user_id}"}
    attrs = 'user_id'

    options = {
      key: key,
      projection_expression: attrs
    }

    resp = $dynamodb_user_teams.get_item(options)

    if resp.item.nil?
      return nil
    end

    return User.find(resp.item['user_id'])
  end
end
