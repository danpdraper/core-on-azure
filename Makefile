SHELL := /usr/bin/env bash

makefile_directory_path := $(realpath $(dir $(realpath $(lastword $(MAKEFILE_LIST)))))
functions_file_path := $(makefile_directory_path)/functions.sh

.PHONY: image

image:
	@if [ -z "$(SNAPCRAFT_KEY_NAME)" ] ; then \
		echo "Please create and register a GPG key for Ubuntu Core model signing, then assign the key name to the SNAPCRAFT_KEY_NAME environment variable. See https://ubuntu.com/core/docs/sign-model-assertion for more information regarding key creation and registration." ; \
		exit 1 ; \
	fi
	@if [ -z "$(GADGET_SNAP_PATH)" ] ; then \
		echo "To the GADGET_SNAP_PATH environment variable, please assign the local path to the gadget snap referenced in $(makefile_directory_path)/my-model.json." ; \
		exit 1 ; \
	fi
	source $(functions_file_path) ; \
		create_raw_image \
			$(SNAPCRAFT_KEY_NAME) \
			$(makefile_directory_path)/my-model.json \
			$(makefile_directory_path)/my-model.model \
			$(GADGET_SNAP_PATH)

.PHONY: disk

disk:
	@if [ -z "$(AZURE_RESOURCE_GROUP_NAME)" ] ; then \
		echo "Please assign the name of the resource group in which you would like the disk to be created to the AZURE_RESOURCE_GROUP_NAME environment variable. The group will be created if it does not already exist." ; \
		exit 1 ; \
	fi
	@if [ -z "$(AZURE_DISK_NAME)" ] ; then \
		echo "Please assign the desired disk name to the AZURE_DISK_NAME environment variable." ; \
		exit 1 ; \
	fi
	source $(functions_file_path) ; \
		create_and_publish_disk \
			$(makefile_directory_path)/pc.img \
			$(makefile_directory_path)/pc.vhd \
			$(AZURE_RESOURCE_GROUP_NAME) \
			$(AZURE_DISK_NAME)
