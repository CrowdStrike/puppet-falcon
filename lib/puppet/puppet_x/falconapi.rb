require 'uri'
require 'net/http'
require 'json'
require 'cgi'

# FalconApi class to interact with the falcon api related to sensor downloads.
class FalconApi
  attr_accessor :falcon_cloud
  attr_accessor :bearer_token
  attr_accessor :update_policy
  attr_accessor :platform_name
  attr_accessor :module_version

  # Initialize a new FalconApi instance.
  # - falcon_cloud - the name of the falcon cloud to use.
  # - bearer_token - the bearer token to use for authentication.
  # - client_id - the client id to generate the bearer token if not provided.
  # - client_secret - the client id to generate the bearer token if not provided.
  # - proxy_host - the proxy host to use for the http client.
  # - proxy_port - the proxy port to use for the http client.
  def initialize(falcon_cloud:, bearer_token: nil, client_id: nil, client_secret: nil, proxy_host: nil, proxy_port: nil)
    if (client_id.nil? || client_secret.nil?) && bearer_token.nil?
      raise ArgumentError, 'client_id and client_secret or bearer_token must be provided'
    end

    @falcon_cloud = falcon_cloud
    @proxy_host = proxy_host
    @proxy_port = proxy_port
    @http_client = http_client
    @bearer_token = if bearer_token.nil?
                      access_token(client_id, client_secret)
                    else
                      bearer_token
                    end
    @client_id = client_id
    @client_secret = client_secret
    @module_version = 'v0.9.0'
  end

  # Returns the version of the sensor installer for the given policy and platform name.
  # - update_policy - the name of the policy to get the version for.
  # - platform_name - the name of the platform to get the version for.
  def version_from_update_policy(update_policy = @update_policy, platform_name = @platform_name)
    query = CGI.escape("platform_name:'#{platform_name}'+name.raw:'#{update_policy}'")
    url_path = "/policy/combined/sensor-update/v2?filter=#{query}"

    request = Net::HTTP::Get.new(url_path)
    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{@bearer_token.unwrap}"
    request['User-Agent'] = "crowdstrike-puppet/#{@module_version}"

    resp = @http_client.request(request)

    case resp
    when Net::HTTPSuccess, Net::HTTPRedirection then

      body = JSON.parse(resp.read_body)

      if body['resources'].nil? || body['resources'].empty?
        raise ArgumentError, "Policy: '#{update_policy}' not found for Platform: '#{platform_name}'"
      end

      unless body['resources'][0]['settings'].key?('sensor_version')
        raise Puppet::Error, "Policy: '#{update_policy}' and Platform: '#{platform_name}' returned zero installer versions"
      end

      body['resources'][0]['settings']['sensor_version']
    else
      raise Puppet::Error, sanitize_error_message("Falcon API error when calling #{url_path} - #{resp.code} #{resp.message} #{resp.body}")
    end
  end

  # Returns a lit of sensor resources that match the provided filter.
  # - query - unescaped string used filter the returned values.
  #   Example: "platform:'windows'+version:'6.2342.12"
  def falcon_installers(query)
    filter = CGI.escape(query)

    url_path = "/sensors/combined/installers/v1?filter=#{filter}"

    request = Net::HTTP::Get.new(url_path)
    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{@bearer_token.unwrap}"
    request['User-Agent'] = "crowdstrike-puppet/#{@module_version}"

    resp = @http_client.request(request)

    case resp
    when Net::HTTPSuccess, Net::HTTPRedirection then
      body = JSON.parse(resp.read_body)

      if body['resources'].nil? || body['resources'].empty?
        raise Puppet::Error, "No installers found for query: '#{query}'"
      end

      body['resources']
    else
      raise Puppet::Error, sanitize_error_message("Falcon API error when calling #{url_path} - #{resp.code} #{resp.message} #{resp.body}")
    end
  end

  # Downloads the sensor installer for the given sha256
  # - sha256 - the sha256 of the sensor installer to download.
  # - out_path - the path to write the installer to.
  def download_installer(sha256, out_path)
    url_path = "/sensors/entities/download-installer/v1?id=#{sha256}"

    request = Net::HTTP::Get.new(url_path)
    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{@bearer_token}"
    request['User-Agent'] = "crowdstrike-puppet/#{@module_version}"

    resp = @http_client.request(request)

    case resp
    when Net::HTTPSuccess, Net::HTTPRedirection then
      File.open(out_path, 'wb') do |file|
        file.write(resp.read_body)
      end
    else
      raise Puppet::Error, sanitize_error_message("Falcon API error when calling #{url_path} - #{resp.code} #{resp.message} #{resp.body}")
    end
  end

  # Private class methods
  private

  # Ensure error message does not include client_id, client_secret, or bearer_token.
  def sanitize_error_message(message)
    [@client_id, @client_secret, @bearer_token].each do |value|
      if value.is_a?(Puppet::Pops::Types::PSensitiveType::Sensitive)
        value = value.unwrap
      end
      message.gsub!(value, '<REDACTED>') if !value.nil? && !value.empty?
    end
    message
  end

  # Returns a new Net::HTTP instance.
  def http_client
    url = URI("https://#{@falcon_cloud}")

    client = Net::HTTP.new(url.host, url.port, @proxy_host, @proxy_port)

    client.use_ssl = true
    client
  end

  # Generates a bearer token for the given client id and client secret.
  # - client_id - the client id to generate the bearer token for.
  # - client_secret - the client secret to generate the bearer token for.
  def access_token(client_id, client_secret)
    url_path = '/oauth2/token'

    req_body = {
      client_id: client_id.unwrap,
      client_secret: client_secret.unwrap
    }

    request = Net::HTTP::Post.new(url_path)
    request['Content-Type'] = 'application/x-www-form-urlencoded'
    request['User-Agent'] = "crowdstrike-puppet/#{@module_version}"
    request.body = URI.encode_www_form(req_body)

    resp = @http_client.request(request)

    case resp
    when Net::HTTPSuccess then
      Puppet::Pops::Types::PSensitiveType::Sensitive.new(JSON.parse(resp.read_body)['access_token'])
    when Net::HTTPRedirection then
      raise Puppet::Error, sanitize_error_message("Error - incorrect value for falcon_cloud: #{@falcon_cloud}. Update the falcon_cloud property with the correct cloud: #{resp.header['Location'].split('/')[2]}")
    else
      raise Puppet::Error, sanitize_error_message("Falcon API error when calling #{url_path} - #{resp.code} #{resp.message} #{resp.body}")
    end
  end
end
