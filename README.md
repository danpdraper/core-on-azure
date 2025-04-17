# Ubuntu-Core-based cloud image

This repo is used to build an Ubuntu-Core-based image meant to be used in an Azure VM.

## Build the raw image

1. Follow https://ubuntu.com/core/docs/sign-model-assertion to create a snapcraft key.
2. Build a local Azure gadget snap following the instructions in https://github.com/danpdraper/pc-gadget/tree/azure
3. Build a local kernel snap from https://git.launchpad.net/~ckt-core-cloud-test/+git/azure-kernel-snaps-uc24
4. Export your snapcraft credentials following the instructions in https://ubuntu.com/core/docs/create-ubuntu-one#heading--snapcraft-credentials
5. Run
    ```bash
    $ SNAPCRAFT_KEY_NAME=<name of snapcraft key> GADGET_SNAP_PATH=<path to local Azure gadget snap> KERNEL_SNAP_PATH=<path to local Azure kernel snap> SNAPCRAFT_STORE_CREDENTIALS=$(cat <path to Snapcraft credentials file>) make raw_image
    ```

## Modify the image

WIP

## Publish the image

To convert the raw image to a fixed-size VHD, publish that VHD to Azure, and create an image gallery image version from that VHD, run the following from this repository's root:

> **Warning**
> Use only a-z and _ characters for the Azure resource group name and disk name as the scripts concat these for the image gallery name and other characters cause issues.

```bash
$ AZURE_RESOURCE_GROUP_NAME=<name of target resource group for disk> AZURE_DISK_NAME=<name of disk> make image_gallery_image_version
```

## Create a VM

```bash
$ AZURE_RESOURCE_GROUP_NAME=<name of target resource group for disk> AZURE_VM_NAME=<name of disk> make azure_vm
```

## Connect to the VM

Get the public IP of the VM from the output of the previous step or with something like:

```bash
az vm show -d -n <vm name> -g <resource group> --query publicIps
```

The above should have created a new ssh key under `~/.ssh`

```bash
ssh -i ~/.ssh/1717589696_845042 -o IdentitiesOnly=yes <your username>@<public ip>
```
