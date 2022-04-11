Puppet::Type.type(:falconctl).provide(:default) do
  desc 'Configure the Falcon Sensor'

  defaultfor kernel: :Linux
  confine kernel: :Linux

  commands falconctl_cmd: '/opt/CrowdStrike/falconctl'

  def cid
    # Since falconctl returns something like this: cid="e853jf9h0234jkh045459hjk".
    # We need to extract the cid from the string.
    begin
      current_cid = (falconctl_cmd '-g', '--cid').strip.gsub(%r{cid="|".}, '')
    rescue => exception
      Puppet.debug("Exception Class: #{exception.class.name}")
      Puppet.debug("Exception Message: #{exception.message}")

      raise exception unless %r{cid is not set}i.match?(exception.message)
      return nil
    end

    desired = @resource[:cid].split('-')[0]

    Puppet.debug("Current cid: #{current_cid}")
    Puppet.debug("Desired cid: #{desired}")

    # If they aren't equal, return the current value.
    unless current_cid.casecmp?(desired)
      return current_cid
    end

    # If they are equal, return the original cid so Puppet thinks they are insync.
    @resource[:cid]
  end

  def cid=(value)
    Puppet.notice("Setting cid to #{value}")
    cmd = ['-sf', "--cid=#{value}"]

    if @resource[:provisioning_token] != :undef
      cmd << "--provisioning-token=#{@resource[:provisioning_token]}"
    end

    falconctl_cmd(*cmd)
  end
end
