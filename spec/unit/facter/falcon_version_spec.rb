# frozen_string_literal: true

require 'spec_helper'
require 'facter'
require 'facter/falcon_version'
require 'puppet'

describe :falcon_version, type: :fact do
  subject(:fact) { Facter.fact(:falcon_version) }

  before :each do
    Facter.clear
    allow(Facter.fact(:kernel)).to receive(:value).and_return('Linux')
  end

  it 'returns a value' do
    # TODO: Not sure how we test this..
    expect(fact.value).to eq(Puppet::Resource.indirection.find('package/falcon-sensor').to_hash[:ensure])
  end
end
