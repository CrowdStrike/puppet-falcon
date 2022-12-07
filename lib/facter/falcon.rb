def falconctl_exec(option)
  stdout = Facter::Core::Execution.execute('/opt/CrowdStrike/falconctl -g --' + option, { on_fail: :raise })
  return if stdout.empty? || stdout.include?('not set')

  output = if stdout.include?('version')
             stdout.gsub(%r{['\s\n]|\(.*\)}, '').split('=')[-1]
           elsif stdout.include?('rfm-reason')
             stdout.gsub(%r{^rfm-reason=|['\s\n\.]|\(.*\)}, '')
           elsif stdout.include?('aph')
             stdout.strip.split('=')[-1].chomp('.')
           else
             stdout.gsub(%r{["\s\n\.]|\(.*\)}, '').split('=')[-1]
           end
  return output if output
rescue
  nil
end

def to_boolean(str)
  str.casecmp('true').zero? || str.casecmp('1').zero?
end

def get_cid
  falconctl_exec('cid')
end

def get_aid
  falconctl_exec('aid')
end

def get_tags
  tags = falconctl_exec('tags')
  return [] unless tags
  tags.split(',')
end

def get_rfm_reason
  falconctl_exec('rfm-reason')
end

def get_rfm_state
  rfm_state = falconctl_exec('rfm-state')
  return if rfm_state.nil?
  to_boolean(rfm_state)
end

def get_apd
  apd = falconctl_exec('apd')
  return if apd.nil?
  !to_boolean(apd)
end

def get_aph
  falconctl_exec('aph')
end

def get_app
  falconctl_exec('app')
end

def get_billing
  falconctl_exec('billing')
end

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
        aid = get_aid
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

      aid = nil if aid.include?('aid is not set.') || aid.empty?

      { aid: aid }
    rescue => exception
      Puppet.debug("Unable to retrieve AID: #{exception}")
      next
    end
  end

  chunk(:tags) do
    begin
      kernel = Facter.value('kernel')

      next unless [ 'Linux' ].include?(kernel)

      tags = Facter::Core::Execution.execute('/opt/CrowdStrike/falconctl -g --tags', { on_fail: :raise }).strip.split('=')[-1].chomp('.')

      tags = if tags.include?('tags are not set.')
               []
             else
               tags.split(',')
             end
      { tags: tags }
    rescue => exception
      Puppet.debug("Unable to retrieve tags: #{exception}")
      next
    end
  end

  chunk(:cid) do
    begin
      kernel = Facter.value('kernel')
      next unless [ 'Linux' ].include?(kernel)

      { cid: get_cid }
    rescue => exception
      Puppet.debug("Unable to retrieve CID: #{exception}")
      next
    end
  end

  chunk(:tags) do
    begin
      kernel = Facter.value('kernel')
      next unless [ 'Linux' ].include?(kernel)

      { tags: get_tags }
    rescue => exception
      Puppet.debug("Unable to retrieve tags: #{exception}")
      next
    end
  end

  chunk(:rfm_state) do
    begin
      kernel = Facter.value('kernel')
      next unless [ 'Linux' ].include?(kernel)

      { rfm: { state: get_rfm_state } }
    rescue => exception
      Puppet.debug("Unable to retrieve RFM state: #{exception}")
      next
    end
  end

  chunk(:rfm_reason) do
    begin
      kernel = Facter.value('kernel')
      next unless [ 'Linux' ].include?(kernel)
      next unless get_rfm_state

      { rfm: { reason: get_rfm_reason } }
    rescue => exception
      Puppet.debug("Unable to retrieve RFM reason: #{exception}")
      next
    end
  end

  chunk(:proxy_enabled) do
    begin
      kernel = Facter.value('kernel')
      next unless [ 'Linux' ].include?(kernel)
      { proxy: { enabled: get_apd } }
    rescue => exception
      Puppet.debug("Unable to retrieve proxy enabled: #{exception}")
      next
    end
  end

  chunk(:proxy_host) do
    begin
      kernel = Facter.value('kernel')
      next unless [ 'Linux' ].include?(kernel)
      { proxy: { host: get_aph } }
    rescue => exception
      Puppet.debug("Unable to retrieve proxy host: #{exception}")
      next
    end
  end

  chunk(:proxy_port) do
    begin
      kernel = Facter.value('kernel')
      next unless [ 'Linux' ].include?(kernel)
      { proxy: { port: get_app } }
    rescue => exception
      Puppet.debug("Unable to retrieve proxy port: #{exception}")
      next
    end
  end

  chunk(:billing) do
    begin
      kernel = Facter.value('kernel')
      next unless [ 'Linux' ].include?(kernel)
      { billing: get_billing }
    rescue => exception
      Puppet.debug("Unable to retrieve billing: #{exception}")
      next
    end
  end
end
