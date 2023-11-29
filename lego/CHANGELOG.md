<!-- https://developers.home-assistant.io/docs/add-ons/presentation#keeping-a-changelog -->
## 0.6.2.1
 - fix typo

## 0.6.2
 - fix env var expansion for numeric values
 - add dnsresolver option, default value 8.8.8.8

## 0.6.1
- Fix bug on multi-domain renewal command line construction

## 0.6.0
- Support SAN certificates
- Bump lego version to v4.14.0
- Bump HA base images to v3.18

## 0.5.0
### Others
- Bump lego version to v4.6.0

## 0.4.0

### New features
- optional restart of addons after certificate update

### Bug fix
- fix HA restart hook

### Improvements
- make option `check_time` optional
- make restart of HA core optional

## 0.3.2

### Bug fix
- fix installed versions of lego per distribution 

## 0.3.1
### Improvements
- switch build to pull binary instead of building from source
- move supporting functions
- log certificate found

### Bug fix
- renew not collecting all arguments
- renew hook requires file

## 0.3.0
### Improvements
- more logs

### Bug fix
- fix sanitization

### Others
- Reverted back to serving HTTP challenge on port `80`, removed `port` option, added port mapping by default
- Improve documentation
- mark addon as `experimental`

## 0.2.1

### Bug fix
- create certificate immediately if does not exist

## 0.2.0

### New Features
- Add `--renew-hook` to automatically restart `Home-Assistant core` when renewing certificate.

### Improvements
- Better check for specific domain certificate, issue each domain severalty.
- Remove config option `interval` in favor of running in specific time. 
- Change port for the `http challenge` from `80` to high port `8091` to free port `80` for other services.
- Change default renew time to `30` days to reduce the renew frequency

### Bug Fix
- Fix command selection done once on addon start.

### Others
- Code cleanup

## 0.1.3
- fix wrong log statement
- enable ingress

## 0.1.2
- Publish docker images instead of local build

## 0.1.0
- First version
