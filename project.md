# How to Configure and Use this Teradata Project

This works in close correlation with code in `.framework`-folder, the code there should be left as is, unless you known what you are doing, for instance adding new feature to the framework. The project-folder is were the magic happen for defining your SQL objects and PowerShell script.

## Configuration

The project is setup in way that deployment to various enviroments is facilitated from the framework, however you still need to configure some setting, for instance the target database for the various environments. Name of the DSN you have configured and other addiational parameter for variable the differ from one environment to another. This is done in t [`.environment.ps1`-](./.configuration/.environments.ps1)

## Definitions

In the `definitions`-folder there are three subfolder, `1-inbound`, `2-intermediate` and `3-delivery`, in the [folder](./definitions/defintions.md) self more detailed information on how to define your table en views.

## Scripts


## Execution


