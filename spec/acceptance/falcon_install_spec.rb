require 'spec_helper_acceptance'

describe 'install falcon' do
  let(:pp) do
    <<-MANIFEST
      class { 'falcon::install':
        falcon_cloud => 'api.us-2.crowdstrike.com',
        client_id => Sensitive('#{ENV['CLIENT_ID']}'),
        client_secret => Sensitive('#{ENV['CLIENT_SECRET']}'),
        update_policy => 'platform_default',
        cid => '#{ENV['CID']}',
      }
    MANIFEST
  end

  it 'applies idempotently' do
    apply_manifest(pp, { catch_failures: true, debug: true })
    apply_manifest(pp, { catch_changes: true, debug: true })
  end

  describe package('falcon-sensor') do
    it { is_expected.to be_installed }
  end
end
