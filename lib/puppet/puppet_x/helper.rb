require 'uri'
require 'net/http'
require 'json'
require 'cgi'

# FalconApi class to interact with the falcon api related to sensor downloads.
class FalconApi
  attr_accessor :falcon_cloud
  attr_accessor :bearer_token
  attr_accessor :policy_name
  attr_accessor :platform_name
  attr_accessor :version

  def initialize(falcon_cloud, client_id, client_secret, scope)
    @falcon_cloud = falcon_cloud
    @http_client = http_client
    @bearer_token = access_token(client_id, client_secret)
    @scope = scope
    @platform_name = platform
  end

  def version_from_policy_name(policy_name = @policy_name)
    url_path = '/policy/combined/sensor-update/v2'

    query = CGI.escape("platform_name:'#{@platform_name}'+name.raw:'#{policy_name}'")

    request = Net::HTTP::Get.new("#{url_path}?filter=#{query}")
    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{@bearer_token.unwrap}"

    resp = @http_client.request(request)

    case resp
    when Net::HTTPSuccess, Net::HTTPRedirection then
      @version = JSON.parse(resp.read_body)['resources'][0]['settings']['sensor_version']
      version
    else
      puts resp.code
      puts resp.header
      puts resp.value
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

    puts request.path

    resp = @http_client.request(request)

    case resp
    when Net::HTTPSuccess, Net::HTTPRedirection then
      JSON.parse(resp.read_body)['resources']
    else
      puts resp.code
      puts resp.header
      puts resp.value
    end
  end

  # TODO: replace os and os_version with facts
  def build_sensor_api_query(_platform_name = @platform_name, version = @version)
    query = "platform:'#{@platform_name.downcase}'"

    unless version.nil?
      query += "+version:'#{@version}'"
    end

    query
  end

  def download_installer(sha256, out_path)

  end

  # Private class methods
  private

  def platform
    if @scope['facts']['os']['macosx']
      return 'Mac'
    end

    @scope['facts']['kernel'].capitalize
  end

  def http_client
    url = URI("https://#{@falcon_cloud}")

    client = Net::HTTP.new(url.host, url.port)
    client.use_ssl = true

    client
  end

  def access_token(client_id, client_secret)
    url_path = '/oauth2/token'

    req_body = {
      client_id: client_id.unwrap,
      client_secret: client_secret.unwrap
    }

    request = Net::HTTP::Post.new(url_path)
    request['Content-Type'] = 'application/x-www-form-urlencoded'
    request.body = URI.encode_www_form(req_body)

    resp = @http_client.request(request)

    case resp
    when Net::HTTPSuccess, Net::HTTPRedirection then
      Puppet::Pops::Types::PSensitiveType::Sensitive.new(JSON.parse(resp.read_body)['access_token'])
    else
      puts resp.code
      puts resp.value
    end
  end
end
