if [ -n "${HTTP_PROXY}" ]; then
	echo "Acquire::http::Proxy \"http://${HTTP_PROXY}\";" >> /etc/apt/apt.conf.d/80proxy
	echo "http_proxy = http://${HTTP_PROXY}" >> /etc/wgetrc
	echo "https_proxy = http://${HTTP_PROXY}" >> /etc/wgetrc
fi
apt-get update
apt-get install -y puppet
