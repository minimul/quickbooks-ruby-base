require 'quickbooks/base'
require 'quickbooks-ruby'

RSpec.configure do |c|
  #config.failure_color = :magenta
  #config.tty = true
  c.color = true
end

$qb_oauth_consumer = OAuth2::Client.new("app_key", "app_secret", {
    :site            => "https://appcenter.intuit.com/connect/oauth2",
    :authorize_url   => "https://appcenter.intuit.com/connect/oauth2",
    :token_url       => "https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer",
    :connection_opts => {}
})
