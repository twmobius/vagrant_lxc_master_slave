if [ -n "${HTTP_PROXY}" ]; then
	echo "Acquire::http::Proxy \"http://${HTTP_PROXY}\";" >> /etc/apt/apt.conf.d/80proxy
fi
apt-get update
apt-get install -y lxc puppet
