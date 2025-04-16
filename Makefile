SHELL := /usr/bin/env bash

makefile_directory_path := $(realpath $(dir $(realpath $(lastword $(MAKEFILE_LIST)))))
functions_file_path := $(makefile_directory_path)/functions.sh

.PHONY: raw_image

raw_image:
	@if [ -z "$(SNAPCRAFT_KEY_NAME)" ] ; then \
		echo "Please create and register a GPG key for Ubuntu Core model signing, then assign the key name to the SNAPCRAFT_KEY_NAME environment variable. See https://ubuntu.com/core/docs/sign-model-assertion for more information regarding key creation and registration." ; \
		exit 1 ; \
	fi
	@if [ -z "$(GADGET_SNAP_PATH)" ] ; then \
		echo "To the GADGET_SNAP_PATH environment variable, please assign the local path to the gadget snap referenced in $(makefile_directory_path)/my-model.json." ; \
		exit 1 ; \
	fi
	@if [ -z "$(KERNEL_SNAP_PATH)" ] ; then \
		echo "To the KERNEL_SNAP_PATH environment variable, please assign the local path to the kernel snap referenced in $(makefile_directory_path)/my-model.json." ; \
	fi
	source $(functions_file_path) ; \
		create_raw_image \
			$(SNAPCRAFT_KEY_NAME) \
			$(makefile_directory_path)/my-model.json \
			$(makefile_directory_path)/my-model.model \
			$(GADGET_SNAP_PATH) \
			$(KERNEL_SNAP_PATH)

.PHONY: image_gallery_image_version

image_gallery_image_version:
	@if [ -z "$(AZURE_RESOURCE_GROUP_NAME)" ] ; then \
		echo "Please assign the name of the resource group in which you would like the image gallery image version to be created to the AZURE_RESOURCE_GROUP_NAME environment variable. The group will be created if it does not already exist." ; \
		exit 1 ; \
	fi
	@if [ -z "$(AZURE_DISK_NAME)" ] ; then \
		echo "Please assign the desired disk name to the AZURE_DISK_NAME environment variable." ; \
		exit 1 ; \
	fi
	source $(functions_file_path) ; \
		create_image_gallery_image_version \
			$(makefile_directory_path)/azure.img \
			$(makefile_directory_path)/azure.vhd \
			$(AZURE_RESOURCE_GROUP_NAME) \
			$(AZURE_DISK_NAME)

.PHONY: azure_vm

azure_vm:
	@if [ -z "$(AZURE_RESOURCE_GROUP_NAME)" ] ; then \
		echo "Please assign the name of the resource group in which you would like the vm to be created to the AZURE_RESOURCE_GROUP_NAME environment variable." ; \
		exit 1 ; \
	fi
	@if [ -z "$(AZURE_VM_NAME)" ] ; then \
		echo "Please assign the desired vm name to the AZURE_VM_NAME environment variable." ; \
		exit 1 ; \
	fi
	source $(functions_file_path) ; create_azure_vm

.PHONY: local_vm

local_vm:
	# https://ubuntu.com/core/docs/testing-with-qemu
	qemu-system-x86_64 \
		-enable-kvm \
		-smp 1 \
		-m 2048 \
		-machine q35 \
		-cpu host \
		-global ICH9-LPC.disable_s3=1 \
		-net nic,model=virtio \
		-net user,hostfwd=tcp::8022-:22 \
		-drive file=OVMF_CODE_4M.fd,if=pflash,format=raw,unit=0,readonly=on \
		-drive file=OVMF_VARS_4M.ms.fd,if=pflash,format=raw,unit=1 \
		-drive "file=azure.img",if=none,format=raw,id=disk1 \
		-device virtio-blk-pci,drive=disk1,bootindex=1 \
		-serial mon:stdio
