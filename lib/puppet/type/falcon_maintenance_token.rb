Puppet::Type.newtype(:falcon_maintenance_token) do
  @doc = <<-DOC
    Temporarily applies a maintenance token to the Falcon Sensor so that
    tamper protection does not block configuration changes or service operations.

    Use `ensure => present` before the changes and `ensure => absent` afterwards.
    `absent` only clears a token that `present` applied during the same Puppet run.
  DOC

  ensurable

  newparam(:name, namevar: true) do
    desc 'The name of the resource'
  end

  newparam(:token) do
    desc 'A pre-generated maintenance token. Takes precedence over retrieving one from the Falcon API.'
  end

  newparam(:client_id) do
    desc 'Falcon API client id used to retrieve a maintenance token'
  end

  newparam(:client_secret) do
    desc 'Falcon API client secret used to retrieve a maintenance token'
  end

  newparam(:falcon_cloud) do
    desc 'The falcon cloud URI to use'
    defaultto 'api.crowdstrike.com'
  end

  newparam(:proxy_host) do
    desc 'The proxy host to use when calling the Falcon API'
  end

  newparam(:proxy_port) do
    desc 'The proxy port to use when calling the Falcon API'
  end

  validate do
    next unless self[:ensure] == :present
    next if self[:token] || (self[:client_id] && self[:client_secret])

    raise Puppet::Error, 'falcon_maintenance_token requires either token or client_id and client_secret'
  end

  private

  def set_sensitive_parameters(sensitive_parameters)
    # Respect sensitive https://tickets.puppetlabs.com/browse/PUP-10950
    [:token, :client_id, :client_secret].each do |param|
      next unless sensitive_parameters.include?(param)

      sensitive_parameters.delete(param)
      parameter(param).sensitive = true
    end
    super
  end
end
