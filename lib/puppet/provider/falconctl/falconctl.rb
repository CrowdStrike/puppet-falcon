require_relative '../../puppet_x/common'

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

  def proxy_host
    begin
      current_proxy_host = (falconctl_cmd '-g', '--aph').strip.split('=')[-1].chomp('.')
    rescue => exception
      Puppet.debug("Exception Class: #{exception.class.name}")
      Puppet.debug("Exception Message: #{exception.message}")

      raise exception unless %r{aph is not set}i.match?(exception.message)
      return nil
    end

    Puppet.debug("Current proxy_host: #{current_proxy_host}")
    Puppet.debug("Desired proxy_host: #{@resource[:proxy_host]}")

    current_proxy_host
  end

  def proxy_host=(value)
    Puppet.notice("Setting proxy_host to #{value}")
    falconctl_cmd('-sf', "--aph=#{value}")
  end

  def proxy_port
    begin
      current_proxy_port = (falconctl_cmd '-g', '--app').strip.split('=')[-1].chomp('.')
    rescue => exception
      Puppet.debug("Exception Class: #{exception.class.name}")
      Puppet.debug("Exception Message: #{exception.message}")

      raise exception unless %r{app is not set}i.match?(exception.message)
      return nil
    end

    Puppet.debug("Current proxy_port: #{current_proxy_port}")
    Puppet.debug("Desired proxy_port: #{@resource[:proxy_port]}")

    current_proxy_port.to_i
  end

  def proxy_port=(value)
    Puppet.notice("Setting proxy_port to #{value}")
    falconctl_cmd('-sf', "--app=#{value}")
  end

  def proxy_enabled
    begin
      current_proxy_enabled = (falconctl_cmd '-g', '--apd').strip.split('=')[-1].chomp('.')

      return current_proxy_enabled unless %r{true|false}i.match?(current_proxy_enabled)

      current_proxy_enabled = !to_boolean(current_proxy_enabled)
    rescue => exception
      Puppet.debug("Exception Class: #{exception.class.name}")
      Puppet.debug("Exception Message: #{exception.message}")

      raise exception unless %r{apd is not set}i.match?(exception.message)
      return nil
    end

    Puppet.debug("Current proxy_enabled: #{current_proxy_enabled}")
    Puppet.debug("Desired proxy_enabled: #{@resource[:proxy_enabled]}")

    current_proxy_enabled.to_s.to_sym
  end

  def proxy_enabled=(value)
    desired_value = !to_boolean(value.to_s)
    if desired_value
      Puppet.debug('Disabling proxy by setting proxy disable to true')
    else
      Puppet.debug('Enabling proxy by setting proxy disable to false')
    end
    falconctl_cmd('-sf', "--apd=#{desired_value}")
  end
end
