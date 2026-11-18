require 'spec_helper_acceptance'

describe 'install falcon' do
  before(:all) do
    ensure_absent_pp = <<-MANIFEST
      package { 'falcon-sensor':
        ensure => 'absent',
      }

      file { '/tmp/stage':
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
            file { '/tmp/stage':
              ensure => 'directory',
              before => Class['falcon'],
            }

            class { 'falcon':
              falcon_cloud => 'api.us-2.crowdstrike.com',
              client_id => Sensitive('#{ENV.fetch('FALCON_CLIENT_ID', nil)}'),
              client_secret => Sensitive('#{ENV.fetch('FALCON_CLIENT_SECRET', nil)}'),
              cid => '#{ENV.fetch('FALCON_CID', nil)}',
              sensor_tmp_dir => '/tmp/stage',
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

          describe 'facts' do
            subject(:output) { command('puppet facts falcon') }

            it 'has a version' do
              expect(output.exit_status).to eq 0
              expect(JSON.parse(output.stdout)['falcon']['version']).not_to be_nil
              expect(JSON.parse(output.stdout)['falcon']['version']).not_to be_empty
              expect(JSON.parse(output.stdout)['falcon']['version']).not_to eq('absent')
            end

            it 'has an aid' do
              expect(output.exit_status).to eq 0
              expect(JSON.parse(output.stdout)['falcon']['aid']).not_to be_nil
              expect(JSON.parse(output.stdout)['falcon']['aid']).not_to be_empty
            end

            it 'has a cid' do
              expect(output.exit_status).to eq 0
              expect(JSON.parse(output.stdout)['falcon']['cid']).to eq(ENV.fetch('FALCON_CID').downcase.split('-').first)
            end
          end
        end
      end
    end

    describe 'update_policy' do
      context 'update_policy=platform_default' do
        manifest = <<-MANIFEST
          file { '/tmp/stage':
            ensure => 'directory',
            before => Class['falcon'],
          }

          class { 'falcon':
            falcon_cloud => 'api.us-2.crowdstrike.com',
            client_id => Sensitive('#{ENV.fetch('FALCON_CLIENT_ID', nil)}'),
            client_secret => Sensitive('#{ENV.fetch('FALCON_CLIENT_SECRET', nil)}'),
            update_policy => 'platform_default',
            sensor_tmp_dir => '/tmp/stage',
            cid => '#{ENV.fetch('FALCON_CID', nil)}',
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

      context 'update_policy=platform_default and version_manage=true' do
        manifest = <<-MANIFEST
          file { '/tmp/stage':
            ensure => 'directory',
            before => Class['falcon'],
          }

          class { 'falcon':
            falcon_cloud => 'api.us-2.crowdstrike.com',
            client_id => Sensitive('#{ENV.fetch('FALCON_CLIENT_ID', nil)}'),
            client_secret => Sensitive('#{ENV.fetch('FALCON_CLIENT_SECRET', nil)}'),
            update_policy => 'platform_default',
            sensor_tmp_dir => '/tmp/stage',
            version_manage => true,
            cid => '#{ENV.fetch('FALCON_CID', nil)}',
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
          file { '/tmp/stage':
            ensure => 'directory',
            before => Class['falcon'],
          }

          class { 'falcon':
            falcon_cloud => 'api.us-2.crowdstrike.com',
            client_id => Sensitive('#{ENV.fetch('FALCON_CLIENT_ID', nil)}'),
            client_secret => Sensitive('#{ENV.fetch('FALCON_CLIENT_SECRET', nil)}'),
            proxy_port => 8080,
            proxy_host => 'proxy.example.com',
            proxy_enabled => true,
            sensor_tmp_dir => '/tmp/stage',
            cid => '#{ENV.fetch('FALCON_CID', nil)}',
          }
        MANIFEST

        it 'applies idempotently' do
          apply_manifest(manifest, { catch_failures: true, debug: true })
          apply_manifest(manifest, { catch_changes: true, debug: true })
        end

        describe 'proxy port' do
          subject(:facts) { command('puppet facts falcon') }

          let(:falconctl) { command('/opt/CrowdStrike/falconctl -g --app') }

          it 'is a fact' do
            expect(facts.exit_status).to eq 0
            expect(JSON.parse(facts.stdout)['falcon']['proxy']['port']).to eq '8080'
          end

          it 'is set in falconctl' do
            expect(falconctl.exit_status).to eq 0
            expect(falconctl.stdout).to match(%r{app=8080})
          end
        end

        describe 'proxy host' do
          subject(:facts) { command('puppet facts falcon') }

          let(:falconctl) { command('/opt/CrowdStrike/falconctl -g --aph') }

          it 'is a fact' do
            expect(facts.exit_status).to eq 0
            expect(JSON.parse(facts.stdout)['falcon']['proxy']['host']).to eq 'proxy.example.com'
          end

          it 'is set in falconctl' do
            expect(falconctl.exit_status).to eq 0
            expect(falconctl.stdout).to match(%r{aph=proxy.example.com})
          end
        end

        describe 'proxy enabled' do
          subject(:facts) { command('puppet facts falcon') }

          let(:falconctl) { command('/opt/CrowdStrike/falconctl -g --apd') }

          it 'is a fact' do
            expect(facts.exit_status).to eq 0
            expect(JSON.parse(facts.stdout)['falcon']['proxy']['enabled']).to be true
          end

          it 'is set in falconctl' do
            expect(falconctl.exit_status).to eq 0
            expect(falconctl.stdout).to match(%r{apd=false}i)
          end
        end

        describe package('falcon-sensor') do
          it { is_expected.to be_installed }
        end
      end

      context 'proxy disabled' do
        manifest = <<-MANIFEST
          file { '/tmp/stage':
            ensure => 'directory',
            before => Class['falcon'],
          }

          class { 'falcon':
            falcon_cloud => 'api.us-2.crowdstrike.com',
            client_id => Sensitive('#{ENV.fetch('FALCON_CLIENT_ID', nil)}'),
            client_secret => Sensitive('#{ENV.fetch('FALCON_CLIENT_SECRET', nil)}'),
            sensor_tmp_dir => '/tmp/stage',
            proxy_enabled => false,
            cid => '#{ENV.fetch('FALCON_CID', nil)}',
          }
        MANIFEST

        it 'applies idempotently' do
          apply_manifest(manifest, { catch_failures: true, debug: true })
          apply_manifest(manifest, { catch_changes: true, debug: true })
        end

        describe 'proxy enabled' do
          subject(:facts) { command('puppet facts falcon') }

          let(:falconctl) { command('/opt/CrowdStrike/falconctl -g --apd') }

          it 'is a fact' do
            expect(facts.exit_status).to eq 0
            expect(JSON.parse(facts.stdout)['falcon']['proxy']['enabled']).to be false
          end

          it 'is set in falconctl' do
            expect(falconctl.exit_status).to eq 0
            expect(falconctl.stdout).to match(%r{apd=true}i)
          end
        end

        describe package('falcon-sensor') do
          it { is_expected.to be_installed }
        end
      end
    end

    describe 'tags' do
      context 'minimum tags' do
        manifest = <<-MANIFEST
          file { '/tmp/stage':
            ensure => 'directory',
            before => Class['falcon'],
          }

          class { 'falcon':
            falcon_cloud => 'api.us-2.crowdstrike.com',
            client_id => Sensitive('#{ENV.fetch('FALCON_CLIENT_ID', nil)}'),
            client_secret => Sensitive('#{ENV.fetch('FALCON_CLIENT_SECRET', nil)}'),
            sensor_tmp_dir => '/tmp/stage',
            tags => ['tag1', 'tag2'],
            tag_membership => minimum,
            cid => '#{ENV.fetch('FALCON_CID', nil)}',
          }
        MANIFEST

        it 'applies idempotently' do
          apply_manifest(manifest, { catch_failures: true, debug: true })
          apply_manifest(manifest, { catch_changes: true, debug: true })
        end

        describe 'facts' do
          subject(:facts) { command('puppet facts falcon') }

          let(:falconctl) { command('/opt/CrowdStrike/falconctl -g --tags') }

          it 'is a fact' do
            expect(facts.exit_status).to eq 0
            expect(JSON.parse(facts.stdout)['falcon']['tags']).to eq ['tag1', 'tag2']
          end

          it 'is set in falconctl' do
            expect(falconctl.exit_status).to eq 0
            expect(falconctl.stdout).to match(%r{tags=tag1,tag2})
          end
        end

        describe package('falcon-sensor') do
          it { is_expected.to be_installed }
        end
      end

      context 'inclusive tags' do
        manifest = <<-MANIFEST
          file { '/tmp/stage':
            ensure => 'directory',
            before => Class['falcon'],
          }

          class { 'falcon':
            falcon_cloud => 'api.us-2.crowdstrike.com',
            client_id => Sensitive('#{ENV.fetch('FALCON_CLIENT_ID', nil)}'),
            client_secret => Sensitive('#{ENV.fetch('FALCON_CLIENT_SECRET', nil)}'),
            tags => ['tag1', 'tag2'],
            sensor_tmp_dir => '/tmp/stage',
            tag_membership => inclusive,
            cid => '#{ENV.fetch('FALCON_CID', nil)}',
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

          describe 'tags' do
            subject(:facts) { command('puppet facts falcon') }

            let(:falconctl) { command('/opt/CrowdStrike/falconctl -g --tags') }

            it 'is a fact' do
              expect(facts.exit_status).to eq 0
              expect(JSON.parse(facts.stdout)['falcon']['tags']).to eq ['tag1', 'tag2']
            end

            it 'is set in falconctl' do
              expect(falconctl.exit_status).to eq 0
              expect(falconctl.stdout).to match(%r{tags=tag1,tag2})
            end
          end

          describe package('falcon-sensor') do
            it { is_expected.to be_installed }
          end
        end

        context 'purge tags' do
          manifest = <<-MANIFEST
          file { '/tmp/stage':
            ensure => 'directory',
            before => Class['falcon'],
          }

          class { 'falcon':
            falcon_cloud => 'api.us-2.crowdstrike.com',
            client_id => Sensitive('#{ENV.fetch('FALCON_CLIENT_ID', nil)}'),
            client_secret => Sensitive('#{ENV.fetch('FALCON_CLIENT_SECRET', nil)}'),
            sensor_tmp_dir => '/tmp/stage',
            tags => [],
            tag_membership => inclusive,
            cid => '#{ENV.fetch('FALCON_CID', nil)}',
          }
          MANIFEST

          command('/opt/CrowdStrike/falconctl -sf --tags=ci,testing') do
            it 'applies idempotently' do
              apply_manifest(manifest, { catch_failures: true, debug: true })
              apply_manifest(manifest, { catch_changes: true, debug: true })
            end

            describe 'tags' do
              subject(:facts) { command('puppet facts falcon') }

              let(:falconctl) { command('/opt/CrowdStrike/falconctl -g --tags') }

              it 'is a fact' do
                expect(facts.exit_status).to eq 0
                expect(JSON.parse(facts.stdout)['falcon']['tags']).to eq []
              end

              it 'is set in falconctl' do
                expect(falconctl.exit_status).to eq 0
                expect(falconctl.stdout).to match(%r{tags are not set})
              end
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
          file { '/tmp/stage':
            ensure => 'directory',
            before => Class['falcon'],
          }

          class { 'falcon':
            falcon_cloud => 'api.us-2.crowdstrike.com',
            cid => '#{ENV.fetch('FALCON_CID', nil)}',
            client_id => Sensitive('#{ENV.fetch('FALCON_CLIENT_ID', nil)}'),
            client_secret => Sensitive('#{ENV.fetch('FALCON_CLIENT_SECRET', nil)}'),
            sensor_tmp_dir => '/tmp/stage',
            version => '#{ENV.fetch('LINUX_SENSOR_VERSION', nil)}',
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
