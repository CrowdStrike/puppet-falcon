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

  newproperty(:tags, array_matching: :all) do
    desc 'List of tags to set for the Falcon Sensor'

    validate do |tag|
      # Tags can include these characters:
      # - Letters (a-z,A-Z)
      # - Numbers (0-9)
      # - Hyphen (-)
      # - Underscore (_)
      # - Forward slash (/)
      #
      # Tags cannot include these characters:
      # - Spaces ( )
      # - Commas (,)
      raise ArgumentError, "Tag: #{tag} must be a string" unless tag.is_a?(String)
      raise ArgumentError, "Tag: #{tag} must not contain spaces" if tag.include?(' ')
      raise ArgumentError, "Tag: #{tag} must not be empty" if tag.empty?

      invalid_characters = tag.scan(%r{[^a-zA-Z0-9\-_\/]}).join
      raise ArgumentError, "Tag: #{tag} contains invalid characters: #{invalid_characters}" unless invalid_characters.empty?
    end

    def change_to_s(currentvalue, newvalue)
      if @resource[:tag_membership] == :minimum
        newvalue = currentvalue + (newvalue - currentvalue)
        return super(currentvalue, newvalue)
      end
      super(currentvalue, newvalue)
    end
  end

  newparam(:tag_membership) do
    desc 'Rather specified tags should be treated as a complete list `inclusive` or as a list of tags to add to the existing list `minimum`.'
    newvalues(:inclusive, :minimum)

    defaultto :minimum
  end
end
