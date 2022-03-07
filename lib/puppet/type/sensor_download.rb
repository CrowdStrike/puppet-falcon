Puppet::Type.newtype(:sensor_download) do
  @doc = 'Download the Falcon Sensor'

  ensurable

  newparam(:name) do
    desc 'The full path to the file.'
  end

  newparam(:sha256) do
    desc 'The sha256 of the package to download'
  end

  newparam(:bearer_token) do
    desc 'The bearer token used to authenticate with the Falcon API'
  end

  newparam(:falcon_cloud) do
    desc 'The falcon cloud URI to use'
  end

  private

  def set_sensitive_parameters(sensitive_parameters)
    # Respect sensitive https://tickets.puppetlabs.com/browse/PUP-10950
    if sensitive_parameters.include?(:bearer_token)
      sensitive_parameters.delete(:bearer_token)
      parameter(:bearer_token).sensitive = true
    end
    super(sensitive_parameters)
  end
end
