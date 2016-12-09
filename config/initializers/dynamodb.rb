options = {
  region: ENV['AWS_REGION'],
  credentials: Aws::Credentials.new(
    ENV['AWS_ACCESS_KEY_ID'],
    ENV['AWS_SECRET_KEY']
  )
}

if ENV['AWS_REGION'] == 'local'
  options.merge!(endpoint: 'http://localhost:8000')
end

$dynamodb_client = Aws::DynamoDB::Client.new(options)

if !$dynamodb_client.list_tables.table_names.include?('splits')
  $dynamodb_client.create_table(
    table_name: 'splits',
    key_schema: [
      {
        attribute_name: 'id',
        key_type: 'HASH'
      }
    ],
    attribute_definitions: [
      {
        attribute_name: 'id',
        attribute_type: 'S'
      }
    ],
    provisioned_throughput: {
      read_capacity_units: 5,
      write_capacity_units: 5
    }
  )
end

if !$dynamodb_client.list_tables.table_names.include?('users')
  $dynamodb_client.create_table(
    table_name: 'users',
    key_schema: [
      {
        attribute_name: 'id',
        key_type: 'HASH'
      }
    ],
    attribute_definitions: [
      {
        attribute_name: 'id',
        attribute_type: 'S'
      }
    ],
    provisioned_throughput: {
      read_capacity_units: 5,
      write_capacity_units: 5
    }
  )
end

if !$dynamodb_client.list_tables.table_names.include?('patreon_users')
  $dynamodb_client.create_table(
    table_name: 'patreon_users',
    key_schema: [
      {
        attribute_name: 'user_id',
        key_type: 'HASH'
      }
    ],
    attribute_definitions: [
      {
        attribute_name: 'user_id',
        attribute_type: 'S'
      }
    ],
    provisioned_throughput: {
      read_capacity_units: 5,
      write_capacity_units: 5
    }
  )
end

if !$dynamodb_client.list_tables.table_names.include?('games')
  $dynamodb_client.create_table(
    table_name: 'games',
    key_schema: [
      {
        attribute_name: 'game_id',
        key_type: 'HASH'
      }
    ],
    attribute_definitions: [
      {
        attribute_name: 'game_id',
        attribute_type: 'S'
      }
    ],
    provisioned_throughput: {
      read_capacity_units: 5,
      write_capacity_units: 5
    }
  )
end

if !$dynamodb_client.list_tables.table_names.include?('twitch_teams')
  $dynamodb_client.create_table(
    table_name: 'twitch_teams',
    key_schema: [
      {
        attribute_name: 'twitch_team_id',
        key_type: 'HASH'
      }
    ],
    attribute_definitions: [
      {
        attribute_name: 'twitch_team_id',
        attribute_type: 'S'
      }
    ],
    provisioned_throughput: {
      read_capacity_units: 5,
      write_capacity_units: 5
    }
  )
end

if !$dynamodb_client.list_tables.table_names.include?('user_twitch_teams')
  $dynamodb_client.create_table(
    table_name: 'user_twitch_teams',
    key_schema: [
      {
        attribute_name: 'user_id',
        key_type: 'HASH'
      }
    ],
    attribute_definitions: [
      {
        attribute_name: 'user_id',
        attribute_type: 'S'
      }
    ],
    provisioned_throughput: {
      read_capacity_units: 5,
      write_capacity_units: 5
    }
  )
end

$dynamodb_splits = Aws::DynamoDB::Table.new('splits', client: $dynamodb_client)
$dynamodb_users = Aws::DynamoDB::Table.new('users', client: $dynamodb_client)
$dynamodb_patreon_users = Aws::DynamoDB::Table.new('patreon_users', client: $dynamodb_client)
$dynamodb_games_with_permalink_redirectors = Aws::DynamoDB::Table.new('games', client: $dynamodb_client)
$dynamodb_twitch_teams = Aws::DynamoDB::Table.new('twitch_teams', client: $dynamodb_client)
$dynamodb_user_teams = Aws::DynamoDB::Table.new('user_twitch_teams', client: $dynamodb_client)
