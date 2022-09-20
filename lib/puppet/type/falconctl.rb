Puppet::Type.newtype(:falconctl) do
  @doc = 'Configure the Falcon Sensor'

  newparam(:name, namevar: true) do
    desc 'The name of the resource'
  end

  newparam(:provisioning_token) do
    desc 'The provisioning token used to register the sensor'
    defaultto :undef
  end

  newproperty(:cid) do
    desc 'The cid to set for the Falcon Sensor'
  end

  newproperty(:proxy_host) do
    desc 'The proxy host to set for the Falcon Sensor'
  end

  newproperty(:proxy_port) do
    desc 'The proxy port to set for the Falcon Sensor'
  end

  newproperty(:proxy_enabled) do
    desc 'Enable or disable the proxy for the Falcon Sensor'
    newvalues(:true, :false)
  end
end
