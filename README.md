a 3-node docker swarm cluster wrapped in a vagrant environment

# Usage

Build and install the [Ubuntu Linux Base Box](https://github.com/rgl/ubuntu-vagrant).

Add the following entries to your `/etc/hosts` file:

```
10.10.0.201 registry.example.com
10.10.0.201 docker1.example.com
10.10.0.202 docker2.example.com
10.10.0.203 docker3.example.com
```

Run `vagrant up` to launch the 3-node cluster.

Try the following endpoints:

* [portainer](http://docker1.example.com:9000): a [Portainer](https://portainer.io/) instance that you can use to manager docker.
* [go-info](http://docker1.example.com:8000): a example that shows how an Go application can use secrets and configs.
