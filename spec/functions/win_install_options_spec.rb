# frozen_string_literal: true

require 'spec_helper'

describe 'falcon::win_install_options' do
  it { is_expected.to run.with_params({ 'CID' => 'A', 'PROXYDISABLE' => nil, 'ProvToken' => nil }).and_return(['CID=A']) }
  it { is_expected.to run.with_params({ 'CID' => 'A', 'PROXYDISABLE' => true, 'ProvToken' => nil }).and_return(['CID=A']) }
  it { is_expected.to run.with_params({ 'CID' => 'A', 'PROXYDISABLE' => false, 'ProvToken' => nil }).and_return(['CID=A', 'PROXYDISABLE=1']) }
end
