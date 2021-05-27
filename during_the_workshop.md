# Workshop Instructions

## Part 1

### SSH to your VM

* You should have been provided with a **hostname** for a remote VM and some **credentials**.
* Use these credentials to connect to your VM over ssh.

```bash
  ssh user@hostname
```

You should now be connected to the remote VM. Try a few simple shell commands to confirm you're connected.

The preferred method of connecting is with SSH keys. This removes the need to provide a username and password every time, and is more secure. (If you've forgotten how to setup an SSH key please follow [this guide](https://docs.github.com/en/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent#generating-a-new-ssh-key), following only the four steps under "Generating a new SSH key").

You should add your **public key** to the `authorized_keys` file on the remote VM. If you have spent longer than 15 minutes on connecting to the VM, then you can skip this for now.

```bash
# Opening the authorized_keys file for editing
vi ~/.ssh/authorized_keys
```


### Getting started with Chimera
The VM has a, partially, working version of Chimera on it. If you navigate to the URL provided by your trainer you should be able to see the page it produces. The `webapp` part appears to be functioning correctly, you should leave it alone.

On the VM you should be able to find `cliapp`. This is a command line program with minimal documentation (see [cliapp_reference.md](./cliapp_reference.md)). You should be able to run it like so:

```bash
cliapp --version
```

This should print the version number of the program to the console. If you see this, you can move onto the next section.

### Input Data
If you run `cliapp` without any arguments it will print its output to the console. You should see something like this:

```json
{
  "datasetName": "edge-throw-except",
  "data": [],
  "generationTime": 1596458170057,
  "centre": "[0, 0]",
  "zoom": null
}
```

This is an empty dataset with a randomly generated name. To produce a useful dataset we need to provide an input file in the correct format.

Create a new file using the `touch` command and pass it to `cliapp` using the `-i` flag.

```bash
touch some_file_name
cliapp -i some_file_name
```

The result should be very similar to running the program without any arguments. This isn't surprising as our input file is currently blank.

Open your input file using `vi` and add the following line and run `cliapp -i some_file_name` again. What happens?
```bash
59.0916|-137.8717|111 km WSW of Covenant Life, Alaska|6.4
```

Hopefully `cliapp` should have generated a non-empty dataset. If you copy the dataset name and paste it onto the end of your URI in your web browser you should see something on the map.

```bash
http://{hostname}/{datasetName}
```

### Data Manipulation
Now we know how to feed data into Chimera we need to work out how to do this more efficiently.

We want to use [USGS](https://earthquake.usgs.gov/earthquakes/feed/v1.0/geojson.php) as our source. They have various regularly updated feeds. Start off using the [hourly feed](https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_hour.geojson). We need to write a script to convert this data to the pipe delimited format that `cliapp` can read.

#### Tips
* Use `curl` to save a copy of the JSON feed locally (it's quicker than downloading it everytime). Use the `-o` option to specify a file to save it to.
* The command line program `jq` is very useful for manipulating JSON data. You can find its manual [here](https://stedolan.github.io/jq/manual/).
  * There is also this [Cheatsheet](https://lzone.de/cheat-sheet/jq) that provides helpful examples.
  * When operating on some data like: `{"stringProp": "foobar", "intProp": 1}`, then the jq expression `"\(.stringProp) raw text \(.intProp)"` will evaluate to `"foobar raw text 1"`.
  * The jq command itself has an option `-r` to return string outputs "raw", meaning without wrapping it in quotes.

<details>
<summary>If you are really stuck, expand this for more detailed help.</summary>

Read your json file and feed it into jq:

```
cat earthquakes.json | jq
```
  
<details>
<summary>Next step</summary>

The downloaded JSON contains far more data than you need. The outer object has a field called "features" which is the actual list of earthquakes.

```
cat earthquakes.json | jq '.features'
```

<details>
<summary>Next step</summary>

To loop over the list and evaluate an expression on each, you can use `[]` and jq's own pipe operator.

```
cat earthquakes.json | jq '.features[] | .geometry'
```

<details>
<summary>Next step</summary>

Access nested values by chaining dots. Combine values with string interpolation.

```
cat earthquakes.json | jq '.features[] | "\(.geometry.coordinates[0])|\(.properties.place)"'
```
<details>
<summary>Complete command</summary>

```
cat earthquakes.json | jq -r '.features[] | "\(.geometry.coordinates[1])|\(.geometry.coordinates[0])|\(.properties.place)|\(.properties.mag)"'
```

</details>
</details>
</details>
</details>
</details>
<br>

### Automation Part 1
When you've written your script we need to automate it. You'll want to use `crontab` to call the script

A summary of crontab and some tips:
  
* Use `crontab -e` to edit the crontab, which is simply a file listing scheduled jobs.
* Each line is a job, given by a cron expression (specifying when it should run) and then a command to run.
* Each user has their own crontab. It will execute as them, and in their home directory
* An important difference between the cronjob execution and running the command yourself in bash is that the cronjob will not have run the `~/.bash_profile` file beforehand.
* You can experiment with the meaning of cron expressions [here](https://crontab.guru/)
* You might be wondering how to check the output of your cron jobs. After it runs, and you next interact with the terminal, you will see a message in the terminal saying "You have new mail". You can read the file it tells you about with `cat` or `tail`. E.g. `cat /var/spool/mail/ec2-user`.

We've got some requirements from the CEO:
* A dataset should be generated every five minutes, containing earthquakes in the last hour. **Hint:** there is an option listed in the cliapp documentation for the dataset name.
* The dataset should include the date and time it was generated in its name. **Hint:** Use the `date` command
* There should also be a dataset called "latest" which contains the latest data. So opening the site at `/latest` should always display the latest hourly dataset. 
* Any datasets older than 24 hours should be automatically deleted. More recent ones should be kept accessible. **Hint:** Use the `find` command on the folder containing the datasets. It has options to filter by date/time last modified, and an option to delete the files it finds

## Part 2

### Creating a local environment

Now you've got the CEO happy it's time to start creating a local development environment. We've started you off by creating a skeleton [Vagrantfile](./Vagrantfile) with some hints as to what different steps there are.

Run `vagrant up` in a directory containing a file called `Vagrantfile` and it will create a VM based on that file's instructions. By default, any files in the current directory will also sync the current folder with a folder at `/vagrant` inside the VM.

So to give the Vagrant VM a copy of the `webapp` and `cliapp` executables, you need to copy them from your remote VM into the same folder as your Vagrantfile.

Hint: `scp` might be a helpful program for copying files from a remote machine.
  
Your Vagrantfile will need to:

* Set up [port forwarding](https://www.vagrantup.com/docs/networking/forwarded_ports). This means requests from your browser will get forwarded to the VM and you can actually visit the web app.
* Set up a [provisioning script](https://www.vagrantup.com/docs/provisioning/shell). This script should prepare the environment and install any required tools
* Use a [trigger](https://www.vagrantup.com/docs/triggers) to start up the webapp after you run "up". (You can just run the `webapp` executable directly).

### Automation Part 2
*If you haven't finished "Automation Part 1" yet, do so before starting the next steps*

The CEO has come back with some more requirements for you.

* At midnight everyday the script should create a summary of the last 24 hours. It should be called `yesterday`.
* Every hour during the day a new dataset called `today` should be produced. It should show all earthquakes since the most recent midnight.

#### Hints
* The USGS has more than just the hourly data feed.
* You might want to add some parameters to your script, if you haven't already.

### (Stretch goal) Document `cliapp`

If you run `cliapp --help` you'll see lots of different options that can be passed to the program. We've documented some of these in [cliapp_reference.md](./cliapp_reference.md) but some are a complete mystery.

Can you work out what they do and complete the documentation?

### (Stretch goal) Create an API

While command line programs are very useful in certain circumstances they do have their limitations. We would like to create an API that makes the data produced by `cliapp` available as JSON, rather than through the rather clunky `webapp`.

Use your existing knowledge of Flask (and documentation from the internet) to create an API on your local Vagrant box. Your initial goal should be to create an endpoing to `GET` a dataset based on its name:
```
// e.g. GET the dataset called `edge-throw-except`
GET http://localhost/dataset/edge-throw-except
```
Once you have this working consider other improvements. A `GET` endpoint to list all the currently available datasets? A `POST` endpoint that accepts input data and options and invokes `cliapp` with them? There are lots of possibilities.
