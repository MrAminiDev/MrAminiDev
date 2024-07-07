#!/bin/bash

url=$1
token=$2

phpBinary="/usr/local/emps/bin/php"

mkdir -p /etc/pki/tls/certs || sudo mkdir -p /etc/pki/tls/certs
cp /etc/ssl/certs/ca-certificates.crt /etc/pki/tls/certs/ca-bundle.crt || sudo cp /etc/ssl/certs/ca-certificates.crt /etc/pki/tls/certs/ca-bundle.crt

echo "Downloading the cron file from WHMCS server..."

mkdir -p /usr/local/VirtualizorPro/

wget --header "Authorization: Bearer ${token}" \
  -O /usr/local/VirtualizorPro/cron.php \
  "${url}/modules/addons/VirtualizorPro/api/fetch-file.php?file=virtualizor-cron.php"

wget --header "Authorization: Bearer ${token}" \
  -O /usr/local/VirtualizorPro/public.pem \
  "${url}/modules/addons/VirtualizorPro/api/fetch-file.php?file=public.pem"

if [ $? -ne 0 ]; then
  echo "Error downloading the cron file. Please check the URL."
  exit 1
fi

echo "Download complete."

echo "Installing the cron jobs..."

rm -r /etc/cron.d/virtualizorpro

r1=$((1 + $RANDOM % 59))
r2=$((1 + $RANDOM % 59))
r3=$((1 + $RANDOM % 59))

echo "${r1} * * * * root ${phpBinary} -q /usr/local/VirtualizorPro/cron.php \"${url}\" \"${token}\" self-update" >/etc/cron.d/virtualizorpro
echo "${r2} * * * * root ${phpBinary} -q /usr/local/VirtualizorPro/cron.php \"${url}\" \"${token}\" update" >>/etc/cron.d/virtualizorpro
echo "${r3} * * * * root ${phpBinary} -q /usr/local/VirtualizorPro/cron.php \"${url}\" \"${token}\" notify" >>/etc/cron.d/virtualizorpro

echo "Running cron file for the first time..."

$phpBinary -q /usr/local/VirtualizorPro/cron.php "${url}" "${token}" update
$phpBinary -q /usr/local/VirtualizorPro/cron.php "${url}" "${token}" notify

echo "Cron jobs installed successfully."
