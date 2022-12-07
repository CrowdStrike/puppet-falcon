build:
	pdk build --force

install: build
	puppet module install pkg/*.tar.gz

# return falcon 
facts:
	puppet facts falcon

### LITMUS TESTS ###

# provision litmus test nodes
litmus-provision:
	pdk bundle exec rake 'litmus:provision_list[local]'

# install puppet
litmus-install-puppet:
	pdk bundle exec rake litmus:install_agent

# install puppet module
litmus-install-module:
	pdk bundle exec rake litmus:install_module

# provision, install puppet, install module
litmus-standup: litmus-provision litmus-install-puppet litmus-install-module
	echo "standup complete"

# reinstall module and run tests
litmus-test: litmus-install-module
	pdk bundle exec rake litmus:acceptance:parallel

# test the module w/o installing it
test:
	pdk bundle exec rake litmus:acceptance:parallel

litmus-destroy:
	pdk bundle exec rake litmus:tear_down