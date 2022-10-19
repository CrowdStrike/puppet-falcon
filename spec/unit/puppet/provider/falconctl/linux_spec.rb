# frozen_string_literal: true

require 'spec_helper'

ensure_module_defined('Puppet::Provider::Linux')
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
    [:cid].each do |property|
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
  end
end
