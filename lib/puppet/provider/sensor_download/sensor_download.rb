require_relative '../../puppet_x/falconapi'

Puppet::Type.type(:sensor_download).provide(:default) do
  desc 'Download sensor package using Ruby'

  def create
    falcon_api = FalconApi.new(falcon_cloud: @resource[:falcon_cloud], bearer_token: @resource[:bearer_token])
    Puppet.notice("Downloading sensor package to location: #{resource[:file_path]}")
    falcon_api.download_installer(@resource['sha256'], @resource['file_path'])

    raise Puppet::Error, "Failed to download sensor package #{@resource[:file_path]}" unless File.exist?(@resource['file_path'])
  end

  def destroy
    Puppet.notice("Deleting #{@resource[:file_path]}")
    File.unlink(@resource[:file_path])
  end

  def exists?
    if Facter.value('falcon').nil?
      falcon_version = :absent
    else
      falcon_version = Facter.value('falcon').fetch('version', :absent)
    end

    installed = [:absent, :purged, :undef, nil].include?(falcon_version) ? false : true

    Puppet.debug("version_manage is #{@resource[:version_manage]}")
    Puppet.debug("falcon_version fact returns #{falcon_version}")
    Puppet.debug("Falcon is installed check returns #{installed}")

    # If version_manage is true check if the installed version is equal to the required version
    if @resource[:version_manage]
      insync = @resource[:version] == Facter.value('falcon_version')
      Puppet.debug("Desired version is equal to installed version: #{insync}")
      return insync
    end

    # If falcon is already installed return insync
    Puppet.debug("Falcon is already installed: #{installed}")
    return true if installed

    # If falcon is absent return file package insync
    Puppet.debug('Falcon is absent checking if sensor package is present')
    File.exist?(@resource[:file_path])
  end
end
