# frozen_string_literal: true

require 'spec_helper'

describe 'falcon' do
  let(:cid) { 'AKDLKJFSDLFJ123KJ1L3' }
  let(:provisioning_token) { 'AKLDFJDSF12312IOJFLKSAF' }

  let(:default_windows_install_options) { ['/install', '/quiet', '/norestart', "CID=#{cid}"] }

  let(:params) do
    {
      client_id: sensitive('example'),
      client_secret: sensitive('example'),
    }
  end

  let(:service_name) do
    case facts[:kernel]
    when 'windows'
      'CSFalconService'
    when 'Darwin'
      'falcon'
    else
      'falcon-sensor'
    end
  end

  let(:package_name) do
    case facts[:kernel]
    when 'windows'
      'CrowdStrike Windows Sensor'
    when 'Darwin'
      'falcon'
    else
      'falcon-sensor'
    end
  end

  let(:installers_response) do
    {
      "resources": [
        {
          "name": 'falcon-sensor-4.1.0-4404.amzn1.x86_64.rpm',
          "sha256": '704992dcd6802279fe02ea5d3707ee8d304439d702481bcee4cd369dbbfc517f',
          "version": '4.1.4404',
        },
        {
          "name": 'falcon-sensor-4.2.0-4404.amzn1.x86_64.rpm',
          "sha256": '704992dcd6802279fe02ea5d3707ee8d304439d702481bcee4cd369dbbfc3333',
          "version": '3.9.4404',
        },
      ],
    }
  end

  let(:mock_versions) do
    [
      '4.1.0-4404',
      '3.9.0-4404',
    ]
  end

  before(:each) do
    stub_request(:post, %r{crowdstrike.com/oauth2/token})
      .with(body: { 'client_id' => 'example', 'client_secret' => 'example' })
      .to_return(status: 200, body: '{"access_token":"example"}', headers: {})

    stub_request(:get, %r{crowdstrike.com/sensors/combined/installers/v1})
      .to_return(status: 200, body: installers_response.to_json, headers: {})
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        os_facts # + {falcon: {version: 'absent'}}
      end

      if os_facts[:kernel] == 'windows'
        let(:params) do
          super().merge(
              cid: cid,
            )
        end
      end

      describe 'with default parameters' do
        it { is_expected.to compile.with_all_deps }

        it { is_expected.to contain_class('falcon::install').that_comes_before('Class[falcon::config]') }
        it { is_expected.to contain_class('falcon::config') }
        it { is_expected.to contain_class('falcon::service').that_subscribes_to('Class[falcon::config]') }
        it { is_expected.to contain_class('falcon::params') }
      end

      describe 'falcon::install' do
        let(:params) do
          super().merge(
              cid: cid,
            )
        end

        context 'when install_method=local' do
          let(:source_param) { 'https://example.com/falcon-sensor-4.1.0-4404.amzn1.x86_64.rpm' }
          let(:ensure_param) { 'present' }

          let(:params) do
            super().merge(
                install_method: 'local',
                package_options: { 'ensure' => ensure_param, 'source' => source_param, 'name' => package_name },
              )
          end

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_package('falcon') }
          it { is_expected.to contain_package('falcon').with_ensure(ensure_param) }
          it { is_expected.to contain_package('falcon').with_source(source_param) }
          it { is_expected.to contain_package('falcon').with_name(package_name) }

          it { is_expected.not_to contain_file('Ensure Package is Removed') }
          it { is_expected.not_to contain_sensor_download('Download Sensor Package') }

          describe 'on windows install' do
            if os_facts[:kernel] == 'windows'

              context 'when provisioning_token is nil' do
                it { is_expected.to contain_package('falcon').with_install_options(default_windows_install_options) }
              end

              context 'when provisioning_token is provided' do
                let(:params) do
                  super().merge(provisioning_token: provisioning_token)
                end
                let(:options) { default_windows_install_options + ["ProvToken=#{provisioning_token}"] }

                it { is_expected.to contain_package('falcon').with_install_options(options) }
              end

              context 'allow install_options to be overridden' do
                let(:params) do
                  super().merge(
                      package_options: { 'ensure' => ensure_param, 'source' => source_param, 'name' => package_name, 'install_options' => ['test'] },
                    )
                end

                it { is_expected.to contain_package('falcon').with_install_options(['test']) }
              end
            end
          end
        end

        context 'when install_method=api' do
          let(:params) do
            super().merge(install_method: 'api')
          end

          it { is_expected.to compile.with_all_deps }

          it { is_expected.to contain_package('falcon') }
          it { is_expected.to contain_package('falcon').with_name(package_name) }

          it { is_expected.to contain_sensor_download('Download Sensor Package') }
          it { is_expected.to contain_sensor_download('Download Sensor Package').that_comes_before('Package[falcon]') }

          describe 'on windows install' do
            if os_facts[:kernel] == 'windows'

              context 'when provisioning_token is nil' do
                it { is_expected.to contain_package('falcon').with_install_options(default_windows_install_options) }
              end

              context 'when provisioning_token is provided' do
                let(:params) do
                  super().merge(provisioning_token: provisioning_token)
                end
                let(:options) { default_windows_install_options + ["ProvToken=#{provisioning_token}"] }

                it { is_expected.to contain_package('falcon').with_install_options(options) }
              end

              context 'allow install_options to be overridden' do
                let(:params) do
                  super().merge(
                      package_options: { 'install_options' => ['test'] },
                    )
                end

                it { is_expected.to contain_package('falcon').with_install_options(['test']) }
              end

              context 'no cid provided' do
                let(:params) do
                  super().merge(cid: :undef)
                end

                it { is_expected.to compile.and_raise_error(%r{CID is required to install the Falcon Sensor on Windows}) }
              end
            end
          end

          describe 'version_decrement' do
            context 'when version_decrement is 0' do
              let(:params) do
                super().merge(version_decrement: 0, version_manage: true)
              end

              it { is_expected.to contain_package('falcon').with_ensure(%r{#{mock_versions[0]}}) }
            end

            context 'when version_decrement is 1' do
              let(:params) do
                super().merge(version_decrement: 1, version_manage: true)
              end

              it { is_expected.to contain_package('falcon').with_ensure(%r{#{mock_versions[1]}}) }
            end
          end

          describe 'version_manage' do
            context 'when version_manage=false' do
              let(:params) do
                super().merge(version_manage: false)
              end

              it { is_expected.to contain_package('falcon').with_ensure('present') }

              context 'when falcon is installed' do
                let(:facts) do
                  super().merge(falcon: { version: '4.1.0-4404' })
                end

                it { is_expected.not_to contain_sensor_download('Download Sensor Package') }
              end

              context 'when falcon is not installed' do
                it { is_expected.to contain_sensor_download('Download Sensor Package') }
              end
            end

            context 'when version_manage=true' do
              let(:params) do
                super().merge(version_manage: true)
              end

              it { is_expected.to contain_sensor_download('Download Sensor Package').with_ensure('present') }
            end
          end

          context 'allow package_name to be overridden' do
            let(:params) do
              super().merge(package_name: 'foo')
            end

            it { is_expected.to contain_package('falcon').with_name('foo') }
          end

          describe 'cleanup_installer' do
            context 'when true' do
              let(:params) do
                super().merge(cleanup_installer: true)
              end

              it { is_expected.to contain_file('Ensure Package is Removed').with_ensure('absent') }
              it { is_expected.to contain_file('Ensure Package is Removed').that_requires('Package[falcon]') }
            end

            context 'when false' do
              let(:params) do
                super().merge(cleanup_installer: false)
              end

              it { is_expected.not_to contain_file('Ensure Package is Removed') }
            end
          end

          context 'client_id and client_secret are required' do
            let(:params) do
              super().merge(client_id: :undef, client_secret: :undef)
            end

            it { is_expected.to compile.and_raise_error(%r{client_id and client_secret are required when install_method is 'api'}) }
          end
        end
      end

      describe 'falcon::config' do
        if os_facts[:kernel] != 'windows'
          it { is_expected.to contain_falconctl('falcon').with_cid(nil) }
          it { is_expected.to contain_falconctl('falcon').with_provisioning_token(nil) }

          context 'with cid' do
            let(:params) { super().merge('cid' => cid) }

            it { is_expected.to contain_falconctl('falcon').with_cid(cid) }
          end

          context 'with provisioning_token' do
            let(:params) { super().merge('provisioning_token' => provisioning_token) }

            it { is_expected.to contain_falconctl('falcon').with_provisioning_token(provisioning_token) }
          end

          context 'when config_manage is false' do
            let(:params) { super().merge('config_manage' => false) }

            it { is_expected.not_to contain_falconctl('falcon') }
          end
        end

        if os_facts[:kernel] == 'windows'
          context 'on windows' do
            it { is_expected.not_to contain_falconctl('falcon') }
          end
        end
      end

      describe 'falcon::service' do
        it { is_expected.to contain_service('falcon').with_ensure('running') }
        it { is_expected.to contain_service('falcon').with_name(service_name) }
        it { is_expected.to contain_service('falcon').with_enable(true) }

        context 'allow service_ensure to be overridden' do
          let(:params) { super().merge('service_ensure' => 'stopped') }

          it { is_expected.to contain_service('falcon').with_ensure('stopped') }
        end

        context 'allow service_enable to be overridden' do
          let(:params) { super().merge('service_enable' => false) }

          it { is_expected.to contain_service('falcon').with_enable(false) }
        end

        context 'allow service_name to be overridden' do
          let(:params) { super().merge('service_name' => 'my-falcon') }

          it { is_expected.to contain_service('falcon').with_name('my-falcon') }
        end

        context 'when service_manage is false' do
          let(:params) { super().merge('service_manage' => false) }

          it { is_expected.not_to contain_service('falcon') }
        end
      end
    end
  end
end
