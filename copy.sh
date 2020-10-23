# version 1.5

echo "Checking APP_ID environment variable"
if [ $APP_ID == "" ]; then
    echo "ERROR: No APP_ID defined"
    exit 1
else
    echo "  PASS"
fi

echo "Checking APP_SECRET environment variable"
if [ $APP_SECRET == "" ]; then
    echo "ERROR: No APP_SECRET defined"
    exit 1
else
    echo "  PASS"
fi

echo "Checking TENANT_ID environment variable"
if [ $TENANT_ID == "" ]; then
    echo "ERROR: No TENANT_ID defined"
    exit 1
else
    echo "  PASS"
fi

echo "Checking SUBSCRIPTION_ID environment variable"
if [ $SUBSCRIPTION_ID == "" ]; then
    echo "ERROR: No SUBSCRIPTION_ID defined"
    exit 1
else
    echo "  PASS"
fi

echo "Logging into Azure CLI"
az login --service-principal -u $APP_ID -p=$APP_SECRET --tenant $TENANT_ID

echo "Setting the subscription ID for Azure CLI"
az account set --subscription $SUBSCRIPTION_ID

echo "Using Azure CLI to create storage account firewall rule"
IP=$(curl https://api.ipify.org?format=text)
az storage account network-rule add -g $RESOURCE_GROUP --account-name $ACCOUNT --ip-address $IP

echo "Sleeping for 20 seconds to allow the rule to update..."
sleep 20
echo "  DONE"

echo "Creating new rclone azure storage account backend"
rclone config create backend azureblob account $ACCOUNT key $KEY

if [ $DIRECTION == "UPLOAD" ]; then
	echo "Creating a new container for this copy"
	rclone mkdir backend:$CONTAINER && "  DONE"

	echo "Verify the container was created"
	rclone lsd backend: | grep $CONTAINER$$ "  DONE"

	echo "Copy all the files to storage account backend"
	rclone copy /filestore/ backend:$CONTAINER --progress

	echo "LS of storage account backend"
	rclone ls backend:$CONTAINER

elif [ $DIRECTION == "DOWNLOAD" ]; then
	# Verify the container was exists
	rclone lsd backend: | grep $CONTAINER && echo "  DONE"

	# Copy all the files to the local machine
	rclone copy backend:$CONTAINER /filestore/ --progress

	# Show all files copied over
	rclone ls /filestore/
else
    echo "ERROR: no direction defined!"
    exit 1
fi