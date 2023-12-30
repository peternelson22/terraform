#!/bin/bash
cat > index.xhtml <<EOF
6
7<h1>Hello, World</h1>
EOF
nohup busybox httpd -f -p ${server_port} &