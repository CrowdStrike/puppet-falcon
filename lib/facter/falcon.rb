# rubocop:disable Style/RedundantBegin
Facter.add(:falcon, type: :aggregate) do
  chunk(:version) do
    begin
      kernel = Facter.value('kernel')

      pkg_name = if kernel == 'Linux'
                   'falcon-sensor'
                 elsif kernel == 'windows'
                   'CrowdStrike Windows Sensor'
                 else
                   'falcon'
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
end
