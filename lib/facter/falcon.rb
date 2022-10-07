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

  chunk(:aid) do
    begin
      kernel = Facter.value('kernel')

      next unless [ 'Linux', 'windows' ].include?(kernel)

      if kernel == 'Linux'
        aid = Facter::Core::Execution.execute('/opt/CrofwdStrike/falconctl -g --aid', { on_fail: :raise })

        if aid.nil? || aid.empty?
          next
        end

        aid = aid.gsub(%r{aid="|".}, '')
      elsif kernel == 'windows'
        require 'win32/registry'

        ['SYSTEM\CrowdStrike\{9b03c1d9-3138-44ed-9fae-d9f4c034b88d}\{16e0423f-7058-48c9-a204-725362b67639}\Default', 'SYSTEM\CurrentControlSet\Services\CSAgent\Sim'].each do |reg_path|
          begin
            Win32::Registry::HKEY_LOCAL_MACHINE.open(reg_path) do |reg|
              aid = reg.read('AG')[-1].unpack('H*')[0]
              break
            end
          rescue Win32::Registry::Error => exception
            Puppet.debug("Registry exception: #{exception}")
            next
          end
        end
      end

      if aid.nil? || aid.empty? || aid.include?('aid is not set.')
        aid = :unset
      end

      { aid: aid }
    rescue => exception
      Puppet.debug("Unable to retrieve AID: #{exception}")
      next
    end
  end
end
