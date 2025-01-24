# USAGOV Logshipper

## Why this project

This repo contains USAGov-specific configuration for the https://github.com/gsa-tts/cg-logshipper.

## Developer setup

You will need the Cloud Foundry command line and a place to deploy the log-shipper in order to test your work. This project uses buildpacks and is not set up to run locally (e.g., in Docker).

Contributors on the USAGov team should run `bin/init` after cloning this repo. Currently, this simply installs a commit-msg hook. Then when starting a new feature, create a branch named for the Jira ticket of a new feature:

```
git checkout -b USAGOV-###-new-feature-branch
```

### Minimal test setup

You can do a smoke-test of the log-shipper in a cloud.gov sandbox. In addition to the services the log-shipper needs, you'll need a log-producer (that is, an app!) connect to your test log-shipper via a log drain. The app can be in the same sandbox or in a separate space (log drains are space-agnostic).

1. Set the following environment variables:
   - HTTP_USER and HTTP_PASS: You can generate random strings, as long as they are suitable for inclusion in a These are basic auth strings that the setup scripts will apply to both the cg-logshipper-creds service it creates, and to the log drains.
   - HTTP_PASS: basic auth password
   - HOSTNAME: a string to distinguish your log-shipper from all the others in its route name. Our deployment tooling uses "usagov-" and the name fo the space where the log-shipper is deployed. (Note that sandbox space names have periods in them, which don't play well in route names.)
   - NEW_RELIC_LICENSE_KEY -- can be a random string if you don't want to send data to New Relic. (The log-shipper strongly assumes you do want to send data to New Relic and won't start up if it doesn't at least have defined credentials. You'll get error messages about not being able to connect and you can ignore them.)
2. _Optionally_, un-comment the first part of `project_conf/fluentbit.conf`, which defines a `stdout` OUTPUT. This will allow you to see the log-shipper's output by using the `cf logs` command.
3. Target the space where the log-shipper will run: `cf target -s my.space`
4. Run `bin/setup-services.sh`. This will create user-provided services "cg-logshipper-creds" and "newrelic-creds," and an s3 service "logshipper-s3."
5. Run `bin/deploy-logshipper.sh' to deploy the app.
6. Run `bin/create-route.sh` to create a route and map it to the log-shipper. (This will use your `HOSTNAME` environment variable.)
7. Target the space where the app(s) that will provide log data are running, if it's different from the space where the log-shipper is deployed: `cf target -s other-space`
8. Run `bin/add-log-drains-for-space.sh`. This will create a log drain and bind it to each app in the space (except for the app named "log-shipper").

## Contributing

See [CONTRIBUTING](CONTRIBUTING.md) for additional information.


## Public domain

This project is in the worldwide [public domain](LICENSE.md). As stated in [CONTRIBUTING](CONTRIBUTING.md):

> This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the [CC0 1.0 Universal public domain dedication](https://creativecommons.org/publicdomain/zero/1.0/).
>
> All contributions to this project will be released under the CC0 dedication. By submitting a pull request, you are agreeing to comply with this waiver of copyright interest.
