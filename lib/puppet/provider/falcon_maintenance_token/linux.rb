require_relative '../../puppet_x/falconapi'

Puppet::Type.type(:falcon_maintenance_token).provide(:linux) do
  desc 'Apply a maintenance token with falconctl'

  defaultfor kernel: :Linux
  confine kernel: :Linux

  commands falconctl_cmd: '/opt/CrowdStrike/falconctl'

  # Tracks whether a token was applied during this Puppet run.
  class << self
    attr_accessor :token_applied
  end

  def exists?
    if @resource[:ensure] == :absent
      # Only act (clear) when we applied a token this run.
      return self.class.token_applied ? true : false
    end

    # Nothing to do (e.g. first install) when the sensor isn't installed yet.
    return true unless File.exist?('/opt/CrowdStrike/falconctl')

    false
  end

  def create
    token = @resource[:token] || retrieve_token
    Puppet.notice('Applying maintenance token to the Falcon Sensor')
    falconctl_cmd('-sf', "--maintenance-token=#{token}")
    self.class.token_applied = true
  end

  def destroy
    Puppet.notice('Clearing maintenance token from the Falcon Sensor')
    falconctl_cmd('-df', '--maintenance-token')
    self.class.token_applied = false
  end

  private

  def retrieve_token
    api = FalconApi.new(
      falcon_cloud: @resource[:falcon_cloud],
      client_id: wrap(@resource[:client_id]),
      client_secret: wrap(@resource[:client_secret]),
      proxy_host: @resource[:proxy_host],
      proxy_port: @resource[:proxy_port],
    )
    api.maintenance_token
  end

  # FalconApi expects Sensitive values; provider receives plain strings.
  def wrap(value)
    Puppet::Pops::Types::PSensitiveType::Sensitive.new(value)
  end
end
