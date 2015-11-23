# Loads on app startup and loads config/marketplace.yml

# Grabbing the config
file_path = Rails.root.join('config', 'marketplace.yml')
if File.exist?(file_path)
  # Loading config
  configuration = YAML.load_file(file_path)
  configuration ? configuration.deep_symbolize_keys! : configuration={}
else
  puts "Warning: Missing config/marketplace.yml file (there's a sample file under config for reference -- alternatively can be specified in the environment too)"
  configuration = {}
end

# Setting up the config - alternatively can be specified in the environment too
ENV['MWS_MARKETPLACE_ID'] = ENV['MWS_MARKETPLACE_ID'] || configuration[:MWS_MARKETPLACE_ID]
ENV['MWS_MERCHANT_ID'] = ENV['MWS_MERCHANT_ID'] || configuration[:MWS_MERCHANT_ID]
ENV['AWS_ACCESS_KEY_ID'] = ENV['AWS_ACCESS_KEY_ID'] || configuration[:AWS_ACCESS_KEY_ID]
ENV['AWS_SECRET_ACCESS_KEY'] = ENV['AWS_SECRET_ACCESS_KEY'] || configuration[:AWS_SECRET_ACCESS_KEY]
