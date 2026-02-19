# frozen_string_literal: true

require 'spec_helper'
require 'puppet/type/sensor_download'

RSpec.describe 'the sensor_download type' do
  it 'loads' do
    expect(Puppet::Type.type(:sensor_download)).not_to be_nil
  end

  describe 'when validating attributes' do
    [:file_path, :sha256, :bearer_token, :falcon_cloud, :version_manage, :version, :proxy_host, :proxy_port].each do |param|
      it "has a #{param} parameter" do
        expect(Puppet::Type.type(:sensor_download).attrtype(param)).to eq(:param)
      end
    end

    it 'has sha256 as namevar' do
      expect(Puppet::Type.type(:sensor_download).key_attributes).to eq([:sha256])
    end

    it 'is ensurable' do
      expect(Puppet::Type.type(:sensor_download).validproperties).to include(:ensure)
    end
  end

  describe 'when validating attribute values' do
    let(:provider) do
      instance_double(
        'provider',
        class: Puppet::Type.type(:sensor_download).defaultprovider,
        clear: nil,
        validate_source: nil,
      )
    end

    before :each do
      allow(Puppet::Type.type(:sensor_download).defaultprovider).to receive(:new).and_return(provider)
    end

    after :each do
      Puppet::Type.type(:sensor_download).defaultprovider = nil
    end

    it 'supports string for file_path' do
      expect {
        Puppet::Type.type(:sensor_download).new(
          sha256: 'abcd1234',
          file_path: '/tmp/falcon_sensor.rpm',
        )
      }.not_to raise_error
    end

    it 'supports string for sha256' do
      expect {
        Puppet::Type.type(:sensor_download).new(
          sha256: 'abcd1234567890',
          file_path: '/tmp/falcon_sensor.rpm',
        )
      }.not_to raise_error
    end

    it 'supports string for bearer_token' do
      expect {
        Puppet::Type.type(:sensor_download).new(
          sha256: 'abcd1234',
          file_path: '/tmp/falcon_sensor.rpm',
          bearer_token: 'token123',
        )
      }.not_to raise_error
    end

    it 'supports string for falcon_cloud' do
      expect {
        Puppet::Type.type(:sensor_download).new(
          sha256: 'abcd1234',
          file_path: '/tmp/falcon_sensor.rpm',
          falcon_cloud: 'us-1',
        )
      }.not_to raise_error
    end

    it 'supports boolean for version_manage' do
      expect {
        Puppet::Type.type(:sensor_download).new(
          sha256: 'abcd1234',
          file_path: '/tmp/falcon_sensor.rpm',
          version_manage: true,
        )
      }.not_to raise_error
    end

    it 'supports string for version' do
      expect {
        Puppet::Type.type(:sensor_download).new(
          sha256: 'abcd1234',
          file_path: '/tmp/falcon_sensor.rpm',
          version: '1.2.3',
        )
      }.not_to raise_error
    end

    it 'supports string for proxy_host' do
      expect {
        Puppet::Type.type(:sensor_download).new(
          sha256: 'abcd1234',
          file_path: '/tmp/falcon_sensor.rpm',
          proxy_host: 'proxy.example.com',
        )
      }.not_to raise_error
    end

    it 'supports integer for proxy_port' do
      expect {
        Puppet::Type.type(:sensor_download).new(
          sha256: 'abcd1234',
          file_path: '/tmp/falcon_sensor.rpm',
          proxy_port: 8080,
        )
      }.not_to raise_error
    end

    it 'supports string for proxy_port' do
      expect {
        Puppet::Type.type(:sensor_download).new(
          sha256: 'abcd1234',
          file_path: '/tmp/falcon_sensor.rpm',
          proxy_port: '8080',
        )
      }.not_to raise_error
    end
  end

  describe 'when handling sensitive parameters' do
    it 'marks bearer_token as sensitive when included in sensitive_parameters' do
      resource = Puppet::Type.type(:sensor_download).new(
        sha256: 'abcd1234',
        file_path: '/tmp/falcon_sensor.rpm',
        bearer_token: 'secret_token',
      )

      # Simulate the sensitive_parameters behavior
      resource.send(:set_sensitive_parameters, [:bearer_token])

      expect(resource.parameter(:bearer_token).sensitive).to be true
    end
  end
end
