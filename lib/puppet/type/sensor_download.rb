Puppet::Type.newtype(:sensor_download) do
  @doc = 'Download the Falcon Sensor'

  ensurable

  newparam(:file_path) do
    desc 'The full path to the file.'
  end

  newparam(:sha256) do
    isnamevar
    desc 'The sha256 of the package to download'
  end

  newparam(:bearer_token) do
    desc 'The bearer token used to authenticate with the Falcon API'
  end

  newparam(:falcon_cloud) do
    desc 'The falcon cloud URI to use'
  end

  newparam(:version_manage) do
    desc 'If true download the required sensor package if current sensor version does not match desired version. False only download sensor package when no sensor is installed'
  end

  newparam(:version) do
    desc 'The falcon sensor version that should be installed.'
  end

  newparam(:proxy_host) do
    desc 'The proxy host to use for downloading the sensor package'
  end

  newparam(:proxy_port) do
    desc 'The proxy port to use for downloading the sensor package'
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
