= Example of using logrotate with balenaOS

This balenaOS example configures logrotate to rotate files matching the pattern 
`/data/log/*.log`

== Behaviour on restart

When the localServer service container is restarted the runCommand.bash script moves all of the files in /data/log to /data/log-backup-yyyymmmdd-hhmm this allows the testing of logrotate will new and unrotated log files. 

== Shared volume

Log files are written to the shared volume /data into /data/log/

- localServer.log is the raw output from the dummy web server
- localServer-runCommand.log is the output of the runCommand.bash script including the output of the dummy web server
- localServer-start.log is logging of the start of the container and device uptime:

```
[2019-11-07 19:35:14.870212] Starting Container localServer
[2019-11-07 19:35:14.873135] Uptime: 19:35:14 up 50 min, 0 users, load average: 0.01, 0.05, 0.07
```

== Manually forcing a logrotation

From a shell, execute

```
/usr/sbin/logrotate /etc/logrotate.conf --state=/data/log/logrotate/status -v -f
```

== Connecting to the dummy web server

After boot, the LocalServer container will start a "dummy web server" on port 80. This is
avilable on port 80 of the Public Device URL provided by balenaOS. The dummy web server will 
log all requests

== Using the DEBUG variable to idle the device

If you define DEBUG as non-empty Device Variable or Device Service Variable for the 
localServer service then the runCommand.bash will initialize the service and then print 

```
Idling...
```

prefixed with a timestamp every ten seconds. This will be also appended to 
localServer-runCommand.log 

= Structure

This is a single service balenaOS Microservices project. The `docker-compose.yml` describes the shared volume, the service `localServer` and it's ports.

== LocalServer

This is a simple http server and overly complex runCommand.bash used in several other
projects. 

util.bash contains functions to 
- initialize logging to console and log files
- 
timestamp the output from bash scripts and other commands. 
