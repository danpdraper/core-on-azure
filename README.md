To build the raw image, run the following from this repository's root:

```
$ SNAPCRAFT_KEY_NAME=<name of GPG key registered with Snapcraft> GADGET_SNAP_PATH=<path to local Azure gadget snap> SNAPCRAFT_STORE_CREDENTIALS=$(cat <path to Snapcraft credentials file>) make image
```

For instructions regarding creation and registration of a GPG key for Ubuntu Core model signing (the name of which you assign to the `SNAPCRAFT_KEY_NAME` variable in the preceding command), see https://ubuntu.com/core/docs/sign-model-assertion. To build a local Azure gadget snap, see https://github.com/danpdraper/pc-gadget/tree/azure. To obtain your Snapcraft credentials (in the interest of assigning those credentials to the `SNAPCRAFT_STORE_CREDENTIALS` variable in the preceding command), see https://ubuntu.com/core/docs/create-ubuntu-one#heading--snapcraft-credentials.

To convert the raw image to a fixed-size VHD, and then publish that VHD to Azure, run the following from this repository's root:

```
$ AZURE_RESOURCE_GROUP_NAME=<name of target resource group for disk> AZURE_DISK_NAME=<name of disk> make disk
```
