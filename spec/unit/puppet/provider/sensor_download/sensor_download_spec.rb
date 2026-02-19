# frozen_string_literal: true

require 'spec_helper'
require 'puppet/provider/sensor_download/sensor_download'

describe Puppet::Type.type(:sensor_download).provider(:default) do
  let(:provider_class) { Puppet::Type.type(:sensor_download).provider(:default) }
  let(:resource) { instance_double('resource') }
  let(:provider) { provider_class.new(resource) }
  let(:falcon_api) { instance_double('FalconApi') }

  before(:each) do
    provider.resource = resource
    allow(resource).to receive(:[]).and_return(:undef)
    allow(resource).to receive(:[]).with(:sha256).and_return('abcd1234567890')
    allow(resource).to receive(:[]).with('sha256').and_return('abcd1234567890')
    allow(resource).to receive(:[]).with(:file_path).and_return('/tmp/falcon_sensor.rpm')
    allow(resource).to receive(:[]).with('file_path').and_return('/tmp/falcon_sensor.rpm')
    allow(resource).to receive(:[]).with(:falcon_cloud).and_return('us-1')
    allow(resource).to receive(:[]).with(:bearer_token).and_return('token123')
    allow(resource).to receive(:[]).with(:proxy_host).and_return(nil)
    allow(resource).to receive(:[]).with(:proxy_port).and_return(nil)
    allow(resource).to receive(:[]).with(:version_manage).and_return(false)
    allow(resource).to receive(:[]).with(:version).and_return('1.2.3')

    # Allow provider.resource to be called
    allow(provider).to receive(:resource).and_return(resource)

    # Mock FalconApi class
    stub_const('FalconApi', Class.new)
    allow(FalconApi).to receive(:new).and_return(falcon_api)
    allow(falcon_api).to receive(:download_installer)
  end

  describe 'when validating methods' do
    it 'has a create method' do
      expect(provider).to respond_to(:create)
    end

    it 'has a destroy method' do
      expect(provider).to respond_to(:destroy)
    end

    it 'has an exists? method' do
      expect(provider).to respond_to(:exists?)
    end
  end

  describe '#create' do
    it 'creates FalconApi instance with correct parameters' do
      allow(File).to receive(:exist?).with('/tmp/falcon_sensor.rpm').and_return(true)
      allow(Puppet).to receive(:notice)

      expect(FalconApi).to receive(:new).with(
        falcon_cloud: 'us-1',
        bearer_token: 'token123',
        proxy_host: nil,
        proxy_port: nil,
      ).and_return(falcon_api)

      provider.create
    end

    it 'calls download_installer with correct parameters' do
      allow(File).to receive(:exist?).with('/tmp/falcon_sensor.rpm').and_return(true)
      allow(Puppet).to receive(:notice)

      expect(falcon_api).to receive(:download_installer).with('abcd1234567890', '/tmp/falcon_sensor.rpm')

      provider.create
    end

    it 'logs download notice message' do
      allow(File).to receive(:exist?).with('/tmp/falcon_sensor.rpm').and_return(true)

      expect(Puppet).to receive(:notice).with('Downloading sensor package to location: /tmp/falcon_sensor.rpm')

      provider.create
    end

    it 'raises error if file does not exist after download' do
      allow(File).to receive(:exist?).with('/tmp/falcon_sensor.rpm').and_return(false)
      allow(Puppet).to receive(:notice)

      expect {
        provider.create
      }.to raise_error(Puppet::Error, 'Failed to download sensor package /tmp/falcon_sensor.rpm')
    end

    it 'creates FalconApi with proxy settings when provided' do
      allow(resource).to receive(:[]).with(:proxy_host).and_return('proxy.example.com')
      allow(resource).to receive(:[]).with(:proxy_port).and_return(8080)
      allow(File).to receive(:exist?).with('/tmp/falcon_sensor.rpm').and_return(true)
      allow(Puppet).to receive(:notice)

      expect(FalconApi).to receive(:new).with(
        falcon_cloud: 'us-1',
        bearer_token: 'token123',
        proxy_host: 'proxy.example.com',
        proxy_port: 8080,
      ).and_return(falcon_api)

      provider.create
    end
  end

  describe '#destroy' do
    it 'logs deletion notice message' do
      allow(File).to receive(:unlink)

      expect(Puppet).to receive(:notice).with('Deleting /tmp/falcon_sensor.rpm')

      provider.destroy
    end

    it 'deletes the file' do
      allow(Puppet).to receive(:notice)

      expect(File).to receive(:unlink).with('/tmp/falcon_sensor.rpm')

      provider.destroy
    end
  end

  describe '#exists?' do
    let(:falcon_fact) { { 'version' => '1.2.3' } }

    before(:each) do
      allow(Facter).to receive(:value).with('falcon').and_return(falcon_fact)
      allow(Puppet).to receive(:debug)
    end

    context 'when version_manage is false' do
      it 'returns true if falcon is installed' do
        expect(provider.exists?).to be true
      end

      it 'returns file existence status if falcon is not installed' do
        allow(Facter).to receive(:value).with('falcon').and_return({ 'version' => :absent })
        allow(File).to receive(:exist?).with('/tmp/falcon_sensor.rpm').and_return(true)

        expect(provider.exists?).to be true
      end

      it 'returns false if falcon is not installed and file does not exist' do
        allow(Facter).to receive(:value).with('falcon').and_return({ 'version' => :absent })
        allow(File).to receive(:exist?).with('/tmp/falcon_sensor.rpm').and_return(false)

        expect(provider.exists?).to be false
      end

      it 'handles nil falcon fact' do
        allow(Facter).to receive(:value).with('falcon').and_return(nil)
        allow(File).to receive(:exist?).with('/tmp/falcon_sensor.rpm').and_return(true)

        expect(provider.exists?).to be true
      end

      it 'handles falcon fact without version key' do
        allow(Facter).to receive(:value).with('falcon').and_return({})
        allow(File).to receive(:exist?).with('/tmp/falcon_sensor.rpm').and_return(true)

        expect(provider.exists?).to be true
      end
    end

    context 'when version_manage is true' do
      before(:each) do
        allow(resource).to receive(:[]).with(:version_manage).and_return(true)
      end

      it 'returns true if installed version matches desired version' do
        expect(provider.exists?).to be true
      end

      it 'returns false if installed version does not match desired version' do
        allow(resource).to receive(:[]).with(:version).and_return('2.0.0')

        expect(provider.exists?).to be false
      end

      it 'returns false if falcon is not installed' do
        allow(Facter).to receive(:value).with('falcon').and_return({ 'version' => :absent })

        expect(provider.exists?).to be false
      end

      it 'handles various absent states' do
        [:absent, :purged, :undef, nil].each do |absent_state|
          allow(Facter).to receive(:value).with('falcon').and_return({ 'version' => absent_state })

          expect(provider.exists?).to be false
        end
      end
    end

    context 'debug logging' do
      it 'logs falcon fact information' do
        expect(Puppet).to receive(:debug).with("Falcon fact: #{falcon_fact}")

        provider.exists?
      end

      it 'logs version_manage setting' do
        expect(Puppet).to receive(:debug).with('version_manage is false')

        provider.exists?
      end

      it 'logs falcon version' do
        expect(Puppet).to receive(:debug).with('falcon_version fact returns 1.2.3')

        provider.exists?
      end

      it 'logs installation status' do
        expect(Puppet).to receive(:debug).with('Falcon is installed check returns true')

        provider.exists?
      end

      it 'logs desired version' do
        expect(Puppet).to receive(:debug).with('Desired falcon version is 1.2.3')

        provider.exists?
      end

      it 'logs version comparison when version_manage is true' do
        allow(resource).to receive(:[]).with(:version_manage).and_return(true)

        expect(Puppet).to receive(:debug).with('Desired version is equal to installed version: true')

        provider.exists?
      end

      it 'logs already installed status when falcon is present' do
        expect(Puppet).to receive(:debug).with('Falcon is already installed: true')

        provider.exists?
      end

      it 'logs file check when falcon is absent' do
        allow(Facter).to receive(:value).with('falcon').and_return({ 'version' => :absent })
        allow(File).to receive(:exist?).with('/tmp/falcon_sensor.rpm').and_return(true)

        expect(Puppet).to receive(:debug).with('Falcon is absent checking if sensor package is present')

        provider.exists?
      end
    end
  end
end
