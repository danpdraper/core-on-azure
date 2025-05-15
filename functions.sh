function echo_error() {
	>&2 echo "[ERROR] $*"
}

function create_raw_image() {
	if [ -z "SNAPCRAFT_STORE_CREDENTIALS" ] ; then
		echo_error "Please set the SNAPCRAFT_STORE_CREDENTIALS environment variable. See https://ubuntu.com/core/docs/create-ubuntu-one#heading--snapcraft-credentials for more information."
		return 1
	fi

	if [ "$#" -ne 5 ] ; then
		echo_error "USAGE: ${FUNCNAME[0]} snapcraft_key_name unsigned_model_path signed_model_path gadget_snap_path kernel_snap_path"
		echo_error "PROVIDED: ${FUNCNAME[0]} $*"
		return 1
	fi
	local snapcraft_key_name="$1"
	local unsigned_model_path="$2"
	local signed_model_path="$3"
	local gadget_snap_path="$4"
	local kernel_snap_path="$5"

	snap sign -k $snapcraft_key_name $unsigned_model_path > $signed_model_path || return $?
	ubuntu-image snap --snap $gadget_snap_path --snap $kernel_snap_path $signed_model_path || return $?
}

BYTES_PER_MEGABYTE=$(( 1024 * 1024 ))

function create_disk_from_raw_image() {
	if [ "$#" -ne 2 ] ; then
		echo_error "USAGE: ${FUNCNAME[0]} raw_image_path local_disk_path"
		echo_error "PROVIDED: ${FUNCNAME[0]} $*"
		return 1
	fi
	local raw_image_path="$1"
	local local_disk_path="$2"

	local raw_sparse_image_path="${raw_image_path}.sparse"

	cp --sparse=always $raw_image_path $raw_sparse_image_path || return $?
	truncate --size 30G $raw_sparse_image_path || return $?
	local sparse_image_size=$(stat --format '%s' $raw_sparse_image_path)
	local rounded_sparse_image_size=$(( ($sparse_image_size / $BYTES_PER_MEGABYTE + 1) * $BYTES_PER_MEGABYTE ))
	qemu-img resize -f raw $raw_sparse_image_path $rounded_sparse_image_size || return $?
	qemu-img convert -f raw -o subformat=fixed,force_size -O vpc $raw_sparse_image_path $local_disk_path || return $?
	rm $raw_sparse_image_path || return $?
}

function publish_disk() {
	if [ "$#" -ne 4 ] ; then
		echo_error "USAGE: ${FUNCNAME[0]} resource_group_name disk_name timestamp_in_seconds local_disk_path"
		echo_error "PROVIDED: ${FUNCNAME[0]} $*"
		return 1
	fi
	local resource_group_name="$1"
	local disk_name="$2"
	local timestamp_in_seconds="$3"
	local local_disk_path="$4"

	az group create --location westeurope --name $resource_group_name || return $?

	local full_disk_name=$(echo ${disk_name}-$(date --date=@$timestamp_in_seconds +'%Y%m%d%H%M%S'))
	local disk_size=$(stat --format '%s' $local_disk_path)
	az disk create \
		--name $full_disk_name \
		--resource-group $resource_group_name \
		--location westeurope \
		--zone 3 \
		--os-type Linux \
		--for-upload \
		--upload-size-bytes $disk_size \
		--sku standard_lrs \
		--hyper-v-generation V2 || return $?

	local disk_access_sas_url=$(
		az disk grant-access \
			--name $full_disk_name \
			--resource-group $resource_group_name \
			--access-level Write \
			--duration-in-seconds 86400 | jq --raw-output .accessSAS)

	azcopy copy $local_disk_path $disk_access_sas_url --blob-type PageBlob || return $?

	az disk revoke-access \
		--name $full_disk_name \
		--resource-group $resource_group_name || return $?
}

function create_image_version_from_disk() {
	if [ "$#" -ne 3 ] ; then
		echo_error "USAGE: ${FUNCNAME[0]} resource_group_name disk_name timestamp_in_seconds"
		echo_error "PROVIDED: ${FUNCNAME[0]} $*"
		return 1
	fi
	local resource_group_name="$1"
	local disk_name="$2"
	local timestamp_in_seconds="$3"

	az sig create \
		--resource-group $resource_group_name \
		--gallery-name ${resource_group_name}_image_gallery

	az sig image-definition create \
		--resource-group $resource_group_name \
		--gallery-name ${resource_group_name}_image_gallery \
		--gallery-image-definition ${resource_group_name}-image-definition \
		--publisher core-on-azure \
		--offer core-on-azure \
		--sku core-on-azure \
		--os-type Linux \
		--os-state generalized

	az sig image-version create \
		--resource-group $resource_group_name \
		--gallery-name ${resource_group_name}_image_gallery \
		--gallery-image-definition ${resource_group_name}-image-definition \
		--gallery-image-version $(date --date=@$timestamp_in_seconds +'%Y.%m.%d%H%M%S') \
		--os-snapshot $(az disk show --name $disk_name --resource-group $resource_group_name --query "id" | tr -d '"')
}

function create_image_gallery_image_version() {
	if [ "$#" -ne 4 ] ; then
		echo_error "USAGE: ${FUNCNAME[0]} raw_image_path local_disk_path resource_group_name disk_name"
		echo_error "PROVIDED: ${FUNCNAME[0]} $*"
		return 1
	fi
	local raw_image_path="$1"
	local local_disk_path="$2"
	local resource_group_name="$3"
	local disk_name="$4"

	local timestamp_in_seconds=$(date +'%s')

	create_disk_from_raw_image $raw_image_path $local_disk_path || return $?
	publish_disk $resource_group_name $disk_name $timestamp_in_seconds $local_disk_path || return $?
	create_image_version_from_disk $resource_group_name $disk_name $timestamp_in_seconds || return $?
}


