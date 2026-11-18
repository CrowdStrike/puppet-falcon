# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:falcon_maintenance_token) do
  it 'accepts a token' do
    expect { described_class.new(name: 'falcon', ensure: :present, token: 'abc') }.not_to raise_error
  end

  it 'accepts API credentials' do
    expect { described_class.new(name: 'falcon', ensure: :present, client_id: 'id', client_secret: 'secret') }.not_to raise_error
  end

  it 'requires a token or API credentials when present' do
    expect { described_class.new(name: 'falcon', ensure: :present) }.to raise_error(Puppet::Error, %r{token or client_id})
  end

  it 'does not require credentials when absent' do
    expect { described_class.new(name: 'falcon', ensure: :absent) }.not_to raise_error
  end
end
