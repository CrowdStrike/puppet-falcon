# falcon
## Table of Contents

1. [Description](#description)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [`api` vs `local` install methods](#api-vs-local-install-methods)
1. [Development - Guide for contributing to the module](#development)
1. [License](#license)

## Description

The `falcon` module installs, configures, and manages the `falcon` service across multiple operating systems and distributions.

> **Note**: `puppet-falcon` is an open source project, not a CrowdStrike product. As such, it carries no formal support, expressed or implied.

# Usage

All parameters for the falcon module are contained within the main `falcon` class. There are many options that will modify what the module does. Refer to [REFERENCE.md](./REFERENCE.md) for more details.

Below are some of the common use cases.

> **Note**: `falcon` packages are not public so this module has two options for installing the falcon sensor. Using the `install_method` parameter you can choose `api` or `local`. `api` is the default. More information is outlined in [API vs Local install methods](#api-vs-local-install-methods).

### Basic Install, Configure, and Manage the service

``` puppet
# using the `api` method

class {'falcon':
  client_id     => Sensitive('12346'),
  client_secret => Sensitive('12345')
}
```

``` puppet
# using the `local` method

$package_options = {
  'ensure' => 'present',
  'source' => '/tmp/sensor.rpm'
  # any other attributes that are valid for the package resource
}

class {'falcon': 
  install_method  => 'local',
  package_options => $package_options
}
```

---

### Using the `api` install method

The  `api` install methods uses the API to download the sensor package. The version of the package that is downloaded are determined by the parameters passed to the module.

There are three parameters that alter the behavior of the `api` install method. Only one of these parameters can be used at a time, and they are evaluated in the order they are listed below.

  - `version` -  Will download the sensor package matching the version you specify.
  - `update_policy` - Will download the version specified by the update policy.
  - `version_decrement` - Will download the `n`th version before the current version.

The drawbacks to using the `api` install method are outlined in [API vs Local install methods](#api-vs-local-install-methods).

Examples for each are below.
**Using the `version` parameter**
  
This takes precedence over `update_policy` and `version_decrement`.

``` puppet
class { 'falcon':
  client_id     => Sensitive('12346'),
  client_secret => Sensitive('12345'),
  version       => '1.0.0'
}
```

**Using the `update_policy` parameter**

This takes precedence over the `version_decrement` parameter.

``` puppet
class { 'falcon':
  client_id     => Sensitive('12346'),
  client_secret => Sensitive('12345'),
  update_policy => 'platform_default'
}
```

**Using the `version_decrement` parameter**

Use `version_decrement` to download the `n-x` version. 

A value of `0` will download the latest version, and a value of `2` will download the `n-2` version (`2` releases behind latest).

``` puppet
class { 'falcon':
  client_id         => Sensitive('12346'),
  client_secret     => Sensitive('12345'),
  version_decrement => 2
}
```

---
### Using the `local` install method

The `local` install method gives you full control on how the sensor is installed. 

Some reasons you may use this method are:
  - You want to install the sensor from a local file
  - You have your own package management system

You can learn more about the `local` install method in [API vs Local install methods](#api-vs-local-install-methods).

When you use the `local` install method, `package_options` is required. Parameters in `package_options` are passed to the the `package` resource. You must provide any required parameters for the `package` resource except the `name` parameter. The module will pick the appropriate name based on the operating system. You can still override the name by specifying the `name` property in the `package_options` hash.


``` puppet
# Using a local file

file {'/tmp/sensor.rpm':
  ensure => 'present',
  source => 'https://company-filer-server.com/sensor.rpm'
}

class {'falcon':
  install_method => 'local',
  package_options => {
    'ensure' => 'present',
    'source' => '/tmp/sensor.rpm'
  },
  require => File['/tmp/sensor.rpm']
}
```

``` puppet
# Using a http source

class {'falcon':
  install_method => 'local',
  package_options => {
    'ensure' => 'present',
    'source' => 'http://example.com/sensor.rpm'
  }
}
```

``` puppet
# Overriding the name parameter

class {'falcon':
  install_method => 'local',
  package_options => {
    'ensure' => 'present',
    'source' => '/tmp/sensor.rpm',
    'name'   => 'falcon-sensor'
  }
}
```

---

### Removing the Installer file

When `install_method` is `api` you can use the `cleanup_installer` parameter to remove the installer file after installation.

``` puppet
class { 'falcon':
  client_id         => Sensitive('12346'),
  client_secret     => Sensitive('12345'),
  cleanup_installer => true
}
```

---

### Overriding the default Package parameters

You can override any parameter that is passed to the `package` resource using the `package_options` parameter. [Valid Package Parameters](https://puppet.com/docs/puppet/7/types/package.html)

This works the same in both `api` and `local` install methods.

``` puppet
$package_options = {
  'provider' => 'rpm',
  'install_options' => '--force',
}

class { 'falcon':
  package_options => $package_options
}
```

---

### Opt out of the module installing the package
``` puppet
class {'falcon':
  package_manage => false
  # ... other required params
}
```

---

### Opt out of the module configuring the agent
``` puppet
class {'falcon':
  config_manage => false
  # ... other required params
}
```

---

### Opt out of the module controlling the service
``` puppet
class {'falcon':
  service_manage => false
  # ... other required params
}
```

---

### Registering a `cid`

``` puppet
class {'falcon':
  cid => 'AJKQUI123JFKSDFJK`
  # ... other required params
}
```

---

### Registering a `cid` with a provisioning token

If your company requires a provisioning token to register a agent, you can use the `provisioning_token` parameter.

``` puppet
class {'falcon':
  cid                => 'AJKQUI123JFKSDFJK`
  provisioning_token => '1234567890'
  # ... other required params
}
```

---


### Pinning the agent version

If you want to pin the agent version to a specific version using the `api` install method then you can set `version_manage` to true.

In our example below we use `version_decrement`, but it works the same for all. Puppet will consult the API to determine what version `version_decrement => 2` resolves to. It then will download that version and ensure it is installed.

Each subsequent run it will check the api to see if the version returned is the one installed. If for example, a new version is released it would cause the version returned from the check to change causing the agent to be upgraded to the new `n-2` version.

> **warning**: This causes the module to consult the API every run to ensure the version the API returns is the version that is installed. This could cause rate limit issues for large deployments. If you want to have automated upgrades/downgrades and use the `api` install method it is generally suggested to set `version_manage` to `false` and allow the CrowdStrike Update Policy to do the upgrades/downgrades instead of Puppet.


``` puppet
class {'falcon':
  version_manage => true
  client_id      => Sensitive('12346'),
  client_secret  => Sensitive('12345'),
  update_policy  => 'platform_default'
  # ... other required params
}
```

Using the `install_method` of `local`

``` puppet
class {'falcon':
  install_method => 'local',
  package_options => {
    'ensure' => '32.4.3',
    'source' => '/tmp/sensor-32.4.3.rpm'
  }
}
```

---
## `api` vs `local` install methods

Generally the `api` method will be fine for most use cases if `version_manage` is set to `false`. If `version_manage` is set to `true` you may run into api rate limits.

You can use `local` install method if you want full control and don't want to leverage the API.

---

### Why are there two install methods?

Generally Puppet modules that manage a package control the full lifecycle of that package from installation to removal. The fact CrowdStrike agent packages are not public makes this hard.

We still wanted to give a hands off way of quickly getting a package installed so we created the `api` install method. This method will require you to provide api credentials, and then we will download the correct package version from the CrowdStrike API. There are parameters that let you control the behavior like setting `update_policy`. This will cause the module to download the correct version based on what the update policy suggests. [Examples of each here](#using-the-api-install-method).

However, this method might not be suitable for everyone so the `local` install method was created that gives you full control on how the sensor is installed.

---

### How the `api` install method works


The api install method will use the falcon api to download the correct package version. The correct package version depends on what parameters you provide. You can see [Examples of each here](#using-the-api-install-method).

The first run will cause Puppet to call the appropriate CrowdStrike apis to get the information needed to download the sensor package. It will then download the sensor package. After that, normal puppet resources take over.

If you set `version_manage` to `true` every run will cause the module to consult the CrowdStrike API to get the appropriate package version. Then it will determine if the installed version is the same as the returned version. If they are not the same, then it will download the correct package version and do the appropriate install/update/downgrade actions.

If you set `version_manage` to `false` then api calls will only happen when the CrowdStrike sensor is not installed.

---

### API rate limits

The main limitation of the `api` install method is api rate limits. We haven't hit them ourselves, but it may be possible for large installations to hit a rate limit when using the `api` install method with `version_manage` set to `true`.

Each time Puppet compiles a catalog for a node it uses the API to determine what version of the agent should be installed. If the agent is already on the correct version then no further apis calls are made.

Setting `version_manage` to `false` will prevent any api calls unless the agent is not installed.

---
### Reducing API calls

The best way to reduce API calls is to set `version_manage` to `false`. This will ensure the only time the API is called is when the agent is not installed. This should prevent API rate limit issues.

## Development

If you want to develop new content or improve on this collection, please open an issue or create a pull request. All contributions are welcome!

## License

See the [LICENSE](LICENSE) for more information.


