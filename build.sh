docker buildx build \
     --progress=plain \
     -t technicalguru/mailserver-opendkim:latest \
     -t technicalguru/mailserver-opendkim:2.11.0.10 \
     -t technicalguru/mailserver-opendkim:2.11.0 \
     -t technicalguru/mailserver-opendkim:2.11 \
     -t technicalguru/mailserver-opendkim:2 \
     --push \
     --platform linux/amd64,linux/arm64 \

#docker build --progress=plain -t technicalguru/mailserver-opendkim:latest .
