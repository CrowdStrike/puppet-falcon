# frozen_string_literal: true

require 'spec_helper'
require 'puppet/type/falconctl'

describe 'the falconctl type' do
  it 'loads' do
    expect(Puppet::Type.type(:falconctl)).not_to be_nil
  end

  describe 'when validating attributes' do
    [:name, :provisioning_token, :tag_membership].each do |param|
      it "has a #{param} parameter" do
        expect(Puppet::Type.type(:falconctl).attrtype(param)).to eq(:param)
      end
    end

    [:cid, :proxy_host, :proxy_port, :proxy_enabled, :tags].each do |property|
      it "has a #{property} property" do
        expect(Puppet::Type.type(:falconctl).attrtype(property)).to eq(:property)
      end
    end

    describe 'when validating attribute values' do
      let(:provider) do
        instance_double(
          'provider',
          class: Puppet::Type.type(:falconctl).defaultprovider,
          clear: nil,
          validate_source: nil,
        )
      end

      before :each do
        allow(Puppet::Type.type(:package).defaultprovider).to receive(:new).and_return(provider)
      end

      after :each do
        Puppet::Type.type(:falconctl).defaultprovider = nil
      end

      it 'supports string for cid' do
        expect {
          Puppet::Type.type(:falconctl).new(name: 'test', cid: '12345')
        }.not_to raise_error
      end

      it 'supports string for provisioning_token' do
        expect {
          Puppet::Type.type(:falconctl).new(name: 'test', cid: '12345', provisioning_token: '12345')
        }.not_to raise_error
      end

      it 'defaults provisioning_token to undef' do
        falconctl = Puppet::Type.type(:falconctl).new(name: 'test', cid: '12345')
        expect(falconctl[:provisioning_token]).to eq(:undef)
      end

      it 'supports string for proxy_host' do
        expect {
          Puppet::Type.type(:falconctl).new(name: 'test', cid: '12345', proxy_host: 'proxy.example.com')
        }.not_to raise_error
      end

      it 'supports numeric for proxy_port' do
        expect {
          Puppet::Type.type(:falconctl).new(name: 'test', cid: '12345', proxy_port: 8080)
        }.not_to raise_error
      end

      it 'supports boolean for proxy_enabled' do
        expect {
          Puppet::Type.type(:falconctl).new(name: 'test', cid: '12345', proxy_enabled: true)
        }.not_to raise_error

        expect {
          Puppet::Type.type(:falconctl).new(name: 'test', cid: '12345', proxy_enabled: false)
        }.not_to raise_error
      end

      it 'supports array for tags' do
        expect {
          Puppet::Type.type(:falconctl).new(name: 'test', cid: '12345', tags: ['tag1', 'tag2'])
        }.not_to raise_error
      end

      it 'only accepts inclusive or minimum for tag_membership' do
        expect {
          Puppet::Type.type(:falconctl).new(name: 'test', cid: '12345', tag_membership: 'inclusive')
        }.not_to raise_error

        expect {
          Puppet::Type.type(:falconctl).new(name: 'test', cid: '12345', tag_membership: 'minimum')
        }.not_to raise_error

        expect {
          Puppet::Type.type(:falconctl).new(name: 'test', cid: '12345', tag_membership: 'exclusive')
        }.to raise_error(Puppet::ResourceError, %r{Invalid value "exclusive"})
      end
    end
  end
end
