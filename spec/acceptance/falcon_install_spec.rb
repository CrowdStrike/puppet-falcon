require 'spec_helper_acceptance'

host_inventory['facter']['os']['release']['major'] 

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

    describe 'tags' do
      context 'minimum tags' do
        manifest = <<-MANIFEST
          class { 'falcon':
            falcon_cloud => 'api.us-2.crowdstrike.com',
            client_id => Sensitive('#{ENV['CLIENT_ID']}'),
            client_secret => Sensitive('#{ENV['CLIENT_SECRET']}'),
            tags => ['tag1', 'tag2'],
            tag_membership => minimum,
            cid => '#{ENV['CID']}',
          }
        MANIFEST

        it 'applies idempotently' do
          apply_manifest(manifest, { catch_failures: true, debug: true })
          apply_manifest(manifest, { catch_changes: true, debug: true })
        end

        describe command('/opt/CrowdStrike/falconctl -g --tags') do
          its(:stdout) { is_expected.to match(%r{tags=tag1,tag2}) }
        end

        describe package('falcon-sensor') do
          it { is_expected.to be_installed }
        end
      end

      context 'inclusive tags' do
        manifest = <<-MANIFEST
          class { 'falcon':
            falcon_cloud => 'api.us-2.crowdstrike.com',
            client_id => Sensitive('#{ENV['CLIENT_ID']}'),
            client_secret => Sensitive('#{ENV['CLIENT_SECRET']}'),
            tags => ['tag1', 'tag2'],
            tag_membership => inclusive,
            cid => '#{ENV['CID']}',
          }
        MANIFEST

        command('/opt/CrowdStrike/falconctl -sf --tags=removetag') do
          it 'applies idempotently' do
            apply_manifest(manifest, { catch_failures: true, debug: true })
            apply_manifest(manifest, { catch_changes: true, debug: true })
          end

          describe command('/opt/CrowdStrike/falconctl -g --tags') do
            its(:stdout) { is_expected.to match(%r{tags=tag1,tag2}) }
          end

          describe package('falcon-sensor') do
            it { is_expected.to be_installed }
          end
        end

        context 'purge tags' do
          manifest = <<-MANIFEST
          class { 'falcon':
            falcon_cloud => 'api.us-2.crowdstrike.com',
            client_id => Sensitive('#{ENV['CLIENT_ID']}'),
            client_secret => Sensitive('#{ENV['CLIENT_SECRET']}'),
            tags => [],
            tag_membership => inclusive,
            cid => '#{ENV['CID']}',
          }
        MANIFEST

          command('/opt/CrowdStrike/falconctl -sf --tags=ci,testing') do
            it 'applies idempotently' do
              apply_manifest(manifest, { catch_failures: true, debug: true })
              apply_manifest(manifest, { catch_changes: true, debug: true })
            end

            describe command('/opt/CrowdStrike/falconctl -g --tags') do
              its(:stdout) { is_expected.to match(%r{tags are not set}) }
            end

            describe package('falcon-sensor') do
              it { is_expected.to be_installed }
            end
          end
        end
      end
    end

    describe 'specific version' do
      context 'install specific version' do
        manifest = <<-MANIFEST
          class { 'falcon':
            falcon_cloud => 'api.us-2.crowdstrike.com',
            cid => '#{ENV['CID']}',
            client_id => Sensitive('#{ENV['CLIENT_ID']}'),
            client_secret => Sensitive('#{ENV['CLIENT_SECRET']}'),
            version => '6.46.14306',
          }
          MANIFEST

        it 'applies idempotently' do
          apply_manifest(manifest, { catch_failures: true, debug: true })
          apply_manifest(manifest, { catch_changes: true, debug: true })
        end
      end
    end
  end
end
