# FTP Server configuration with security
In this practice I am going to set up an FTP server and a DNS server on a private network.
The diagram is:  
![diagram](https://github.com/xtabay00/FTP-Practice/assets/151829005/480c059c-d3bc-4b72-baf5-76f25b45da35)

I am going to use Vagrant to create the virtual machines.

## Table of contents
  - [Description](#description)
  - [FTP server](#ftp-server)
    - [Two servers on one machine](#two-servers-on-one-machine)
    - [Configuration of the Anonymous FTP Server](#configuration-of-the-anonymous-ftp-server)
    - [Configuration of the Local FTP Server](#configuration-of-the-local-ftp-server)
  - [SSL layer](#ssl-layer)
  - [DNS Server](#dns-server)
  - [Provision file](#provision-file)

## Description
In a virtual machine called 'ftp' with 2 network cards there will be 2 ftp servers with different configurations: one for anonymous users and the other for local users. In the latter, a security layer will have to be added.
There will also be a DNS server in another virtual machine called 'dns' and it will be the zone master 'sri.ies'.

## FTP server
I create a virtual machine called 'ftp' with 2 network cards with Vagrant.
```ruby
          Vagrant.configure("2") do |config|
            config.vm.box = "debian/bullseye64"
          
            config.vm.provider "virtualbox" do |vb|
                vb.memory = "256"  #RAM
                vb.linked_clone = true
            end #provider
          
            config.vm.define "ftp" do |debian|
                debian.vm.hostname = "ftp"
                #Network card, bridge mode
                debian.vm.network :private_network, ip: "192.168.57.20"
                debian.vm.network :private_network, ip: "192.168.57.30"
                debian.vm.provision "shell", path: "provision.sh"
            end
          end
```
*Fragment of: Vagrantfile*

### Two servers on one machine
We can set up 2 ftp servers in the same machine. We will just need 2 network cards, 2 different configuration files and some other settings.
By default, when you install the vsftpd software on a debian machine, the configuration file is created in /etc/vsftpd.conf. And the daemon is saved in /lib/systemd/system/vsftpd.service.
#### Steps
1. Create a directory to store the 2 configuration files: 
```bash
mkdir /etc/vsftpd
cp /vagrant/ftp/local.conf /etc/vsftpd/
cp /vagrant/ftp/anon.conf /etc/vsftpd/
```
*Fragment of: provision.sh*
We will create the files later.

2. Create 2 different services and disable the default one.
The service files are a copy of the original but change the path to the configuration file.
```
[Unit]
Description=vsftpd FTP server
After=network.target

[Service]
Type=simple
ExecStart=/usr/sbin/vsftpd /etc/vsftpd/anon.conf
ExecReload=/bin/kill -HUP $MAINPID
ExecStartPre=-/bin/mkdir -p /var/run/vsftpd/empty

[Install]
WantedBy=multi-user.target
```
*Example of a service file: vsftpd-anon.service*

```bash
mkdir /etc/vsftpd
cp /vagrant/ftp/vsftpd-anon.service /etc/systemd/system/
cp /vagrant/ftp/vsftpd-local.service /etc/systemd/system/
systemctl disable --now vsftpd
systemctl enable --now vsftpd-anonymous
systemctl enable --now vsftpd-local
```
*Fragment of: provision.sh*

### Configuration of the Anonymous FTP Server
Requirements:
- Configure the FTP server to allow anonymous connections.
- Set secure access permissions for shared directories.
- Local users are not allowed.
- Anonymous users has NO write permissions.
- Anonymous users are not asked for an anonymous password.
- Data connection timeout will be 30 secs.
- Limit max data transfer bandwidth to 5KB/s
- The server shows a banner "Welcome to SRI FTP anonymous server"
- The server shows an ascii art file in the land directory.
- Test the configuration with passive and active connection mode.
#### Procedure
After installing the vsftpd software, I will modify the configuration file.
With this configuration, I set the listening IP, in standalone mode (it is always active) and only listens on IPv4 sockets:
```
listen=YES
listen_ipv6=NO
listen_address=192.168.57.20
```
To allow anonymous connections without asking any password and to avoid local ones :
```
anonymous_enable=YES
no_anon_password=YES
local_enable=NO
```
To prevent them from uploading anything to the server:
```
write_enable=NO
```
To set the bandwidth limit for downloading and timeout:
```
data_connection_timeout=30
anon_max_rate=5120
```
To set secure access permissions for shared directories, I have created a shared folder (_public_) and set anonymous users to access this folder by default and removed write permissions on it:
```
mkdir /srv/ftp/public
chmod 755 /srv/ftp/public
```
*Fragment of: provision.sh*
```
anon_root=/srv/ftp/public
```
*Fragment of: anon.conf*
To place a banner and have it display an ascii art file:
```
dirmessage_enable=YES
ftpd_banner=Welcome to SRI FTP anonymous server
```
And copy the _.message_ file into the landing folder (_/srv/ftp/public/_).

#### Verification
Let's see if it works. We can test it from a graphical client or from the command line.
  + FileZilla
      - Active mode:  
 ![fz-ftp 20](https://github.com/xtabay00/FTP-Practice/assets/151829005/f67aa188-a794-4007-b0fb-7b25c2da2caa)

      - Passive mode:
 ![fz-pftp 20](https://github.com/xtabay00/FTP-Practice/assets/151829005/3dad2636-f1bc-4ff5-b3e6-68ef81983c37)

To see that the connection is passive, I tried to upload a file to the server and I got an error because I don't have write permission.
  + From the command line
    - Active mode:  
![ftp 20](https://github.com/xtabay00/FTP-Practice/assets/151829005/a2ab5185-816b-406b-a474-43e5db14297e)

    - Passive mode:  
![pftp 20](https://github.com/xtabay00/FTP-Practice/assets/151829005/8aa7efb7-5a46-4a2b-92ea-0813aff5f8c2)

### Configuration of the Local FTP Server
#### Procedure
I create the users:
```
useradd -m -s /bin/bash charles
echo 'charles:1234' | chpasswd
useradd -m -s /bin/bash laura
echo 'laura:1234' | chpasswd
```
*Fragment of: provision.sh*
I set the listening IP:
```
listen_address=192.168.57.30
```
Banner:
```
ftpd_banner=Welcome to SRI FTP Server.
```
I allow only local users access and give them write permission:
```
anonymous_enable=NO
local_enable=YES
write_enable=YES
```
I jail only Charles:
```
chroot_local_user=NO
chroot_list_enable=YES
allow_writeable_chroot=YES
```
With __chroot_local_user=NO_ and _chroot_list_enable=YES_, users have free movement within the server except those listed in the _vsftpd.chroot_list_ file. The _allow_writeable_chroot=YES_ directive is set to avoid login problems with write permissions (depends on the version).
Finally, for security, so that Charles can't bypass the jailing directive, I change the permissions on his folder:
```
chmod 555 /home/charles
```
*Fragment of: provision.sh*
#### Verification
Let's see if it works.
  + FileZilla
      - Laura:  
        ![fz-ftp 30](https://github.com/xtabay00/FTP-Practice/assets/151829005/ea6d950d-5cf9-4b76-8d01-4a6c077fc2e8)
      - Charles:  
        ![fz-ftp 30_char](https://github.com/xtabay00/FTP-Practice/assets/151829005/3275f5c0-993f-458f-82ba-9f30dea6cc5b)

  + From the command line
    - Laura:  
![ftp 30_lau](https://github.com/xtabay00/FTP-Practice/assets/151829005/5aab1643-4841-4494-9442-e4f4deae1b83)


    - Charles:  
![ftp 30_char](https://github.com/xtabay00/FTP-Practice/assets/151829005/dbe7f29a-d045-4ca4-8e87-e5144cfe1b4c)


We see that Charles is jailed and Laura can see the whole server.

## SSL layer
If we do not activate the SSL connection, the communications between the client and the server are in clear text, which can leave them vulnerable to various types of attacks:
	- Sniffing
 	- Data modification attacks
  	- Spoofing
   	- Command injection during transfer (to look for vulnerabilities in our server)
	- Disclosure of sensitive information
 To mitigate these risks, it is highly recommended to use secure connections using SSL/TLS encryption on your FTP server. Enabling SSL/TLS helps protect the confidentiality and integrity of communications and ensures that credentials and transmitted data are secure.
 
### Procedure
Now I am going to add a security layer on the local server.
I enable SSL access and indicate the location of the private key and certificate:
```
ssl_enable=YES
rsa_cert_file=/etc/ssl/certs/server.crt
rsa_private_key_file=/etc/ssl/private/private_key.pem
```
I enforce secure local user connections and data transmission:
```
force_local_data_ssl=YES
force_local_logins_ssl=YES
```
### Verification
Now when I connect from FileZilla, it shows me the certificate.  
![cert](https://github.com/xtabay00/FTP-Practice/assets/151829005/33f5cd69-7fbc-48a7-8d9d-c191b416d21d)

And it connects securely.    
![fz-ssl](https://github.com/xtabay00/FTP-Practice/assets/151829005/7242b41c-de75-4c44-81fe-6fe3ba2ce93a)

We will verify the encryption using a protocol analyser such as WireShark.
Before SSL:  
![no-ssl](https://github.com/xtabay00/FTP-Practice/assets/151829005/707b7b68-7d04-4721-a84e-2b1c64f2ffab)

And if we look at the stream :  
![ssl-no-stream](https://github.com/xtabay00/FTP-Practice/assets/151829005/6223d59f-0c95-498b-a0fc-2197f3a14b41)

After SSL:  
![ssl-yes](https://github.com/xtabay00/FTP-Practice/assets/151829005/cb0371ed-3501-4cc1-8df8-9d689454d8b6)

Stream:  
![ssl-yes-stream](https://github.com/xtabay00/FTP-Practice/assets/151829005/d4bdeb2b-5163-4353-bea2-503f88275832)

## DNS server
I create a virtual machine called 'dns' with Vagrant on the same network.
```ruby
  config.vm.define "dns" do |dns|
    dns.vm.hostname = "dns"
    dns.vm.network :private_network, ip: "192.168.57.10"
    dns.vm.provision "shell", path: "provision-dns.sh"
  end
```
*Fragment of: Vagrantfile*
### Procedure
I have configured the DNS in a basic way, complying with the following:
- Listen for IPv4 requests.
  ```
	OPTIONS="-u bind -4"
  ```
*Fragment of: named
- Forward to server 1.1.1.1.1 and other configurations.
  ```
	acl trusted {
		127.0.0.0/8; 192.168.57.0/24;
	};
	options {
	        directory "/var/cache/bind";
	        forwarders { 1.1.1.1; };
	        allow-transfer { none;};
	        dnssec-validation no;
	        listen-on port 53 { 192.168.57.10; 127.0.0.1; };
	        allow-recursion { trusted; };
	};
  ```
*File: named.conf.options*
- I declare the zone "sri.ies." and the reverse resolution zone.
  ```
	zone "sri.ies." {
	     type master;
	     file "/var/lib/bind/sri.ies.dns";
	};
	zone "57.168.192.in-addr.arpa" {
	     type master;
	     file "/var/lib/bind/192.168.57.rev";
	};
  ```
*File: named.conf.local*.
- I create the zone file with the following addresses
  ```
	; name servers (NS)
	@	 			IN  NS	ns.sri.ies.
	; hosts (A)
	ns   			IN	A	192.168.57.10
	ftp 			IN	A	192.168.57.30
	mirror  		IN 	A	192.168.57.20
  ```
*Fragment of: sri.ies.dns*
- And the corresponding inverse resolution zone file.
  ```
	; name servers (NS)
	@		IN		NS		ns.sri.ies.
	; hosts (A)
	10		IN		PTR		ns.sri.ies.
	20		IN      PTR     mirror.sri.ies.
	30		IN      PTR     ftp.sri.ies.
  ```
*Fragment of: 192.168.57.rev*

## Provision file
Apart from all the files, for automation with Vagrant, I have created 2 provision files, one per virtual machine.
In them is everything explained above, the installation of the services, the copy of the relevant configuration files and the enabling of the services.
I have also added this command : _sed -i 's,s,,,;s, *$,,,' [/file/path]_ to avoid problems when changing format.

If you want to deploy this practice, download the whole folder, go to it from cmd and run "vagrant up".
