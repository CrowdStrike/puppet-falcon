# devcontainer


For format details, see https://aka.ms/devcontainer.json. 

For config options, see the README at:
https://github.com/microsoft/vscode-dev-containers/tree/v0.140.1/containers/puppet
 
``` json
{
	"name": "Puppet Agent, PDK, Bolt",
	"dockerFile": "Dockerfile",
	// Add the IDs of extensions you want installed when the container is created.
	"extensions": [
		"puppet.puppet-vscode",
		"misogi.ruby-rubocop",
		"castwide.solargraph"
	],
	"settings": {
		"[ruby]": {
			"editor.defaultFormatter": "misogi.ruby-rubocop"
		},
		"ruby.rubocop.suppressRubocopWarnings": true,
	},
	"mounts": [
		"source=${localWorkspaceFolder},target=/etc/puppetlabs/code/environments/production/modules/falcon,type=bind,consistency=cached",
	],
	"postStartCommand": "bundle install"
}
```



