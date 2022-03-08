require_relative '../../puppet_x/falconapi'

Puppet::Type.type(:sensor_download).provide(:default) do
  desc 'Download sensor package using Ruby'

  def create
    falcon_api = FalconApi.new(falcon_cloud: @resource[:falcon_cloud], bearer_token: @resource[:bearer_token])
    falcon_api.download_installer(@resource['sha256'], @resource['name'])
  end

  def destroy
    File.unlink(@resource[:name])
  end

  def exists?
    File.exist?(@resource[:name])
  end
end
