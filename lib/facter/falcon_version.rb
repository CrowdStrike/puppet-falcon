Facter.add(:falcon_version) do
  # TODO: Verify windows and macos package names = `falcon-sensor`. If they don't use :kernal to set the correct key.
  setcode do
    Puppet::Resource.indirection.find('package/falcon-sensor').to_hash[:ensure]
  end
end
