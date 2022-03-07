# frozen_string_literal: true

require 'spec_helper'
require 'puppet/type/sensor_download'

RSpec.describe 'the sensor_download type' do
  it 'loads' do
    expect(Puppet::Type.type(:sensor_download)).not_to be_nil
  end
end
