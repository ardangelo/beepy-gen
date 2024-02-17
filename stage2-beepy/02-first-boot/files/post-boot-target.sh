#!/bin/sh

# Start post-boot services
if [ -z "$SSH_CLIENT" ]; then
(nohup sudo systemctl start post-boot.target &>/dev/null ||: &)
fi
