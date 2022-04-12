Facter.add(:falcon_version) do
  confine kernel: 'Linux'
  # TODO: Verify windows and macos package names = `falcon-sensor`. If they don't use :kernal to set the correct key.
  setcode do
    pkg_name = 'falcon-sensor'
    pkg_ensure = Puppet::Resource.indirection.find("package/#{pkg_name}").to_hash[:ensure]

    Puppet.debug("#{pkg_name} returned ensure: #{pkg_ensure}")

    if [:purged, :absent, :undef].include?(pkg_ensure)
      pkg_ensure = :absent
    end

    pkg_ensure
  rescue => exception
    Puppet.debug("#{pkg_name} returned exception: #{exception}")
    :absent
  end
end
