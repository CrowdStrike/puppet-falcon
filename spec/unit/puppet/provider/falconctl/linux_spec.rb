# frozen_string_literal: true

require 'spec_helper'

require 'puppet/provider/falconctl/linux'

describe Puppet::Type.type(:falconctl).provider(:linux) do
  let(:provider_class) { Puppet::Type.type(:falconctl).provider(:linux) }
  let(:resource) { instance_double('resource') }
  let(:provider) { provider_class.new(resource) }

  before(:each) do
    provider.resource = resource
    allow(resource).to receive(:[]).and_return(:undef)
    allow(resource).to receive(:[]).with(:name).and_return('test')

    allow(provider).to receive(:command).with(:falconctl_cmd).and_return('/opt/CrowdStrike/falconctl')
    allow(provider).to receive(:falconctl_cmd)
  end

  describe 'when validating methods' do
    [:cid, :proxy_host, :proxy_port, :proxy_enabled, :tags].each do |property|
      it "has a #{property} method" do
        expect(provider).to respond_to(property)
      end

      it "has a #{property}= method" do
        expect(provider).to respond_to("#{property}=")
      end
    end
  end

  describe 'when validating method values' do
    it 'only pass --cid when not passing provisioning_token' do
      allow(resource).to receive(:[]).with(:cid).and_return('12345')
      allow(provider).to receive(:falconctl_cmd).with('-sf', "--cid=#{resource[:cid]}").and_return(0)

      expect(provider).to receive(:falconctl_cmd).with('-sf', "--cid=#{resource[:cid]}")

      provider.cid = resource[:cid]
    end

    it 'has --provisioning-token when passing provisioning_token' do
      allow(resource).to receive(:[]).with(:cid).and_return('12345')
      allow(resource).to receive(:[]).with(:provisioning_token).and_return('abcdefg')
      allow(provider).to receive(:falconctl_cmd).with('-sf', "--cid=#{resource[:cid]}", "--provisioning-token=#{resource[:provisioning_token]}").and_return(0)

      expect(provider).to receive(:falconctl_cmd).with('-sf', "--cid=#{resource[:cid]}", "--provisioning-token=#{resource[:provisioning_token]}")

      provider.cid = resource[:cid]
    end

    it 'returns cid passed to provider' do
      allow(resource).to receive(:[]).with(:cid).and_return('12345-01')
      allow(provider).to receive(:falconctl_cmd).with('-g', '--cid').and_return('12345')

      expect(provider).to receive(:falconctl_cmd).with('-g', '--cid')
      expect(provider.cid).to eq(resource[:cid])
    end

    it 'returns cid returned from falconctl command' do
      allow(resource).to receive(:[]).with(:cid).and_return('12345')
      allow(provider).to receive(:falconctl_cmd).with('-g', '--cid').and_return('5')

      expect(provider.cid).to eq('5')
    end

    it 'returns proxy_host passed to provider' do
      allow(resource).to receive(:[]).with(:proxy_host).and_return('proxy.example.com')
      allow(provider).to receive(:falconctl_cmd).with('-g', '--aph').and_return('proxy.example.com')

      expect(provider).to receive(:falconctl_cmd).with('-g', '--aph')
      expect(provider.proxy_host).to eq(resource[:proxy_host])
    end

    it 'returns proxy_host returned from falconctl command' do
      allow(resource).to receive(:[]).with(:proxy_host).and_return('proxy.example.com')
      allow(provider).to receive(:falconctl_cmd).with('-g', '--aph').and_return('proxy.example.com')

      expect(provider.proxy_host).to eq('proxy.example.com')
    end

    it 'returns proxy_port passed to provider' do
      allow(resource).to receive(:[]).with(:proxy_port).and_return(123)
      allow(provider).to receive(:falconctl_cmd).with('-g', '--app').and_return('123')

      expect(provider).to receive(:falconctl_cmd).with('-g', '--app')
      expect(provider.proxy_port).to eq(resource[:proxy_port])
    end

    it 'returns proxy_port returned from falconctl command' do
      allow(resource).to receive(:[]).with(:proxy_port).and_return(123)
      allow(provider).to receive(:falconctl_cmd).with('-g', '--app').and_return('123')

      expect(provider.proxy_port).to eq(123)
    end

    it 'returns proxy_enabled passed to provider' do
      allow(resource).to receive(:[]).with(:proxy_enabled).and_return(:true)
      allow(provider).to receive(:falconctl_cmd).with('-g', '--apd').and_return('false')

      expect(provider).to receive(:falconctl_cmd).with('-g', '--apd')
      expect(provider.proxy_enabled).to eq(resource[:proxy_enabled])
    end

    it 'returns proxy_enabled returned from falconctl command' do
      allow(resource).to receive(:[]).with(:proxy_enabled).and_return(:true)
      allow(provider).to receive(:falconctl_cmd).with('-g', '--apd').and_return('false')

      expect(provider.proxy_enabled).to eq(:true)
    end

    it 'returns tags passed to provider' do
      allow(resource).to receive(:[]).with(:tags).and_return(['tag1', 'tag2'])
      allow(provider).to receive(:falconctl_cmd).with('-g', '--tags').and_return('tags=tag1,tag2.')

      expect(provider).to receive(:falconctl_cmd).with('-g', '--tags')
      expect(provider.tags).to eq(resource[:tags])
    end

    it 'returns tags returned from falconctl command' do
      allow(resource).to receive(:[]).with(:tags).and_return('tag1,tag2')
      allow(provider).to receive(:falconctl_cmd).with('-g', '--tags').and_return('tags=tag1,tag2.')

      expect(provider.tags).to eq(['tag1', 'tag2'])
    end
  end
end
