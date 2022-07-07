Facter.add(:falcon, type: :aggregate) do
  chunk(:version) do

    kernel = Facter.value('kernel')

    if kernel == 'Linux'
      pkg_name = 'falcon-sensor'
    elsif kernel == 'windows'
      pkg_name = 'CrowdStrike Windows Sensor'
    else
      pkg_name = 'falcon'
    end

    pkg_ensure = Puppet::Resource.indirection.find("package/#{pkg_name}").to_hash[:ensure]

    Puppet.debug("#{pkg_name} returned ensure: #{pkg_ensure}")

    if [:purged, :absent, :undef].include?(pkg_ensure)
      pkg_ensure = :absent
    end

    { version: pkg_ensure }
  rescue => exception
    Puppet.debug("#{pkg_name} returned exception: #{exception}")
    { version: :absent }
  end
end
