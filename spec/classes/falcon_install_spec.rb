# frozen_string_literal: true

require 'spec_helper'

describe 'falcon::install' do
  before(:each) do
    stub_request(:post, %r{crowdstrike.com/oauth2/token})
      .with(body: { 'client_id' => 'example', 'client_secret' => 'example' })
      .to_return(status: 200, body: '{"access_token":"example"}', headers: {})

    installers_response = {
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

    stub_request(:get, %r{crowdstrike.com/sensors/combined/installers/v1})
      .to_return(status: 200, body: installers_response.to_json, headers: {})
  end

  let(:params) do
    {
      cid: 'example',
      client_id: sensitive('example'),
      client_secret: sensitive('example'),
      install_method: 'api',
    }
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        os_facts
      end

      describe 'when install_method=api' do
        it { is_expected.to compile.with_all_deps }

        it { is_expected.to contain_class('falcon::install') }

        it { is_expected.to contain_sensor_download('Download Sensor Package') }

        it { is_expected.to contain_package('Install Falcon Sensor') }
        it { is_expected.to contain_package('Install Falcon Sensor').with_ensure('present') }

        it { is_expected.to contain_file('Ensure Package is Removed').that_requires('Package[Install Falcon Sensor]') }

        if os_facts[:kernel] == 'Linux'
          it { is_expected.to contain_falconctl('Configure Falcon').that_requires('Package[Install Falcon Sensor]').that_notifies('Service[falcon-sensor]') }

          it { is_expected.to contain_service('falcon-sensor').that_requires('Package[Install Falcon Sensor]') }
        end

        describe 'when cid is not set' do
          let(:params) do
            {}
          end

          it { is_expected.to compile.and_raise_error(%r{expects a value for parameter 'cid'}) }
        end

        describe 'when client_id and client_secret are undef' do
          let(:params) do
            super().merge(client_id: :undef, client_secret: :undef)
          end

          it { is_expected.to compile.and_raise_error(%r{client_id and client_secret are required when install_method is 'api'}) }
        end
      end
    end
  end
end
