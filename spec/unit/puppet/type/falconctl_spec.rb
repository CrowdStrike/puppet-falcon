# frozen_string_literal: true

require 'spec_helper'
require 'puppet/type/falconctl'

describe 'the falconctl type' do
  it 'loads' do
    expect(Puppet::Type.type(:falconctl)).not_to be_nil
  end

  describe "when validating attributes" do
    [:name, :provisioning_token].each do |param|
      it "should have a #{param} parameter" do
        expect(Puppet::Type.type(:falconctl).attrtype(param)).to eq(:param)
      end
    end

    it "should have an cid property" do
      expect(Puppet::Type.type(:falconctl).attrtype(:cid)).to eq(:property)
    end
  end

  describe "when validating attribute values" do
    before :each do
      @provider = double(
        'provider',
        :class           => Puppet::Type.type(:falconctl).defaultprovider,
        :clear           => nil,
        :validate_source => nil
      )
      allow(Puppet::Type.type(:package).defaultprovider).to receive(:new).and_return(@provider)
    end

    after :each do
      Puppet::Type.type(:falconctl).defaultprovider = nil
    end

    it "should support string for cid" do
      expect {
        Puppet::Type.type(:falconctl).new(:name => 'test', :cid => '12345')
      }.to_not raise_error
    end

    it "should support string for provisioning_token" do
      expect {
        Puppet::Type.type(:falconctl).new(:name => 'test', :cid => '12345', :provisioning_token => '12345')
      }.to_not raise_error
    end

    it "should default provisioning_token to undef" do
      falconctl = Puppet::Type.type(:falconctl).new(:name => 'test', :cid => '12345')
      expect(falconctl[:provisioning_token]).to eq(:undef)
    end
  end
end
