# PODMAN Setup


```
[registries.search]
registries = ['registry.access.redhat.com', 'registry.redhat.io', 'docker.io']

[registries.insecure]
registries = []

[registries.block]
registries = []
```


```

# Add content to
$> sudo nano /etc/containers/registries.conf

# Reboot service
$> sudo systemctl restart podman


```
