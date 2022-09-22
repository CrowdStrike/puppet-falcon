require 'spec_helper_acceptance'

describe 'install falcon' do
  before(:all) do
    ensure_absent_pp = <<-MANIFEST
      package { 'falcon-sensor':
        ensure => 'absent',
      }
    MANIFEST

    apply_manifest(ensure_absent_pp, catch_failures: true)
  end

  describe 'install_method=api' do
    describe 'version_decrement' do
      [0, 1].each do |version_decrement|
        context "version_decrement=#{version_decrement}" do
          manifest = <<-MANIFEST
            class { 'falcon':
              falcon_cloud => 'api.us-2.crowdstrike.com',
              client_id => Sensitive('#{ENV['CLIENT_ID']}'),
              client_secret => Sensitive('#{ENV['CLIENT_SECRET']}'),
              cid => '#{ENV['CID']}',
              version_decrement => #{version_decrement},
            }
          MANIFEST

          it 'applies idempotently' do
            apply_manifest(manifest, { catch_failures: true, debug: true })
            apply_manifest(manifest, { catch_changes: true, debug: true })
          end

          describe package('falcon-sensor') do
            it { is_expected.to be_installed }
          end
        end
      end
    end

    describe 'update_policy' do
      context 'update_policy=platform_default' do
        manifest = <<-MANIFEST
          class { 'falcon':
            falcon_cloud => 'api.us-2.crowdstrike.com',
            client_id => Sensitive('#{ENV['CLIENT_ID']}'),
            client_secret => Sensitive('#{ENV['CLIENT_SECRET']}'),
            update_policy => 'platform_default',
            cid => '#{ENV['CID']}',
          }
        MANIFEST

        it 'applies idempotently' do
          apply_manifest(manifest, { catch_failures: true, debug: true })
          apply_manifest(manifest, { catch_changes: true, debug: true })
        end

        describe package('falcon-sensor') do
          it { is_expected.to be_installed }
        end
      end
    end

    describe 'proxy settings' do
      context 'port and host' do
        manifest = <<-MANIFEST
          class { 'falcon':
            falcon_cloud => 'api.us-2.crowdstrike.com',
            client_id => Sensitive('#{ENV['CLIENT_ID']}'),
            client_secret => Sensitive('#{ENV['CLIENT_SECRET']}'),
            proxy_port => 8080,
            proxy_host => 'proxy.example.com',
            proxy_enabled => true,
            cid => '#{ENV['CID']}',
          }
        MANIFEST

        it 'applies idempotently' do
          apply_manifest(manifest, { catch_failures: true, debug: true })
          apply_manifest(manifest, { catch_changes: true, debug: true })
        end

        describe command('/opt/CrowdStrike/falconctl -g --app') do
          its(:stdout) { is_expected.to match(%r{app=8080}) }
        end

        describe command('/opt/CrowdStrike/falconctl -g --aph') do
          its(:stdout) { is_expected.to match(%r{aph=proxy.example.com}) }
        end

        describe command('/opt/CrowdStrike/falconctl -g --apd') do
          its(:stdout) { is_expected.to match(%r{apd=false}i) }
        end

        describe package('falcon-sensor') do
          it { is_expected.to be_installed }
        end
      end

      context 'proxy disabled' do
        manifest = <<-MANIFEST
          class { 'falcon':
            falcon_cloud => 'api.us-2.crowdstrike.com',
            client_id => Sensitive('#{ENV['CLIENT_ID']}'),
            client_secret => Sensitive('#{ENV['CLIENT_SECRET']}'),
            proxy_enabled => false,
            cid => '#{ENV['CID']}',
          }
        MANIFEST

        it 'applies idempotently' do
          apply_manifest(manifest, { catch_failures: true, debug: true })
          apply_manifest(manifest, { catch_changes: true, debug: true })
        end

        describe command('/opt/CrowdStrike/falconctl -g --apd') do
          its(:stdout) { is_expected.to match(%r{apd=true}i) }
        end

        describe package('falcon-sensor') do
          it { is_expected.to be_installed }
        end
      end
    end
  end
end
