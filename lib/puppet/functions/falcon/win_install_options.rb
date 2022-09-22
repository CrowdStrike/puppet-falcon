# Helper function to generate install options for falcon on windows machines
Puppet::Functions.create_function(:"falcon::win_install_options") do
  # @param options install options for falcon to be parsed
  # @return [Hash] transformed install options for falcon
  # @example Calling the function
  #   falcon::win_install_options({ 'CID' => 'SDLFK1123JKLFAL})
  #
  # @api private
  #
  dispatch :win_install_options do
    param 'Hash', :options
    return_type 'Array'
  end
  def win_install_options(options)
    # convert PROXYDISABLE value to the appropriate value for falcon
    # we use the inverse so if the user sets proxy_enabled to false, we set PROXYDISABLE to 1
    # if the user sets proxy_enabled to true, we remove the PROXYDISABLE key
    install_options = options.dup
    if install_options.key?('PROXYDISABLE')
      unless install_options['PROXYDISABLE'].nil?
        install_options['PROXYDISABLE'] = install_options['PROXYDISABLE'] ? nil : 1
      end
    end

    install_options.compact.map { |k, v| "#{k}=#{v}" }
  end
end
