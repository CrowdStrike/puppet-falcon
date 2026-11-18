# frozen_string_literal: true

require 'webmock/rspec'

# Disable remote connections to prevent API calls while unit testing
WebMock.disable_net_connect!(allow_localhost: true)
