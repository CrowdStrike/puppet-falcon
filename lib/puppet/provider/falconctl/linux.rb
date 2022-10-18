require_relative '../../puppet_x/common'

# rubocop:disable Style/RedundantBegin
Puppet::Type.type(:falconctl).provide(:linux) do
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
      Puppet.notice('Disabling proxy by setting proxy disable to true')
    else
      Puppet.notice('Enabling proxy by setting proxy disable to false')
    end
    falconctl_cmd('-sf', "--apd=#{desired_value}")
  end

  def tags
    begin
      current_tags = (falconctl_cmd '-g', '--tags').strip.split('=')[-1].chomp('.').to_s
      current_tags = [] if %r{tags are not set}i.match?(current_tags)

      current_tags = current_tags.split(',') unless current_tags.is_a?(Array)
    rescue => exception
      Puppet.debug("Exception Class: #{exception.class.name}")
      raise exception unless %r{tags are not set}i.match?(exception.message)
    end

    Puppet.debug("Using #{@resource[:tag_membership]} tag membership")
    Puppet.debug("Current tags: #{current_tags}")
    if @resource[:tag_membership] == :minimum
      Puppet.debug("Ensuring tags: #{@resource[:tags]} exists in current tags: #{current_tags}")
      return @resource[:tags] if (@resource[:tags] - current_tags).empty?
    else
      Puppet.debug("Ensuring tags only contain: #{@resource[:tags]}")
    end

    current_tags
  end

  def tags=(value)
    begin
      tags = if @resource[:tag_membership] == :minimum
               current_tags = (falconctl_cmd '-g', '--tags').strip.split('=')[-1].chomp('.').to_s
               current_tags = [] if %r{tags are not set}i.match?(current_tags)
               current_tags = current_tags.split(',') unless current_tags.is_a?(Array)
               current_tags.concat(value - current_tags)
             else
               value
             end

      raise Puppet::Error, "Tags can not exceed 256 characters including comma delimiter. Current length: #{tags.length}" if tags.length > 256

      falconctl_cmd('-sf', "--tags=#{tags.join(',')}")
    rescue => exception
      Puppet.debug("Exception Class: #{exception.class.name}")
      raise Puppet::Error, "Failed to set tags: #{exception.message}"
    end
  end
end
