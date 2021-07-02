Vagrant.configure("2") do |config|
    config.vm.box = "hashicorp/bionic64"

    # Open a port (port forwarding?)
    config.vm.network "forwarded_port", guest: 5000, host: 8080

    # Set up environment variables (Use a shell provisioner?)
    config.vm.provision "shell", path: "shell.sh"

    # Install any dependencies

    # Run the server on `vagrant up` (Trigger?)
    config.trigger.after :up do |trigger|
        trigger.name = "webapp"
        trigger.info = "Starting webapp"
        trigger.run_remote = {inline: "webapp"}
    end
end
