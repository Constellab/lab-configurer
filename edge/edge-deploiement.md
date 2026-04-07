# Install ubuntu on NIPOGI mini PC

- Connect the USB bootable key on usb port behind
- Connect a keyboard and press all F1, F2... keys and start pc
- Check that the keyboard is recognized
- Start ubuntu in graphics safe mode
- Follow installation
  
## Configuration ubuntu

- `sudo apt-get install git -y`
- Create constellab dir: `mkdir /home/constellab/Constellab`
- `cd /home/constellab/Constellab`
- Clone lab-configurer repository: `git clone https://github.com/Constellab/lab-configurer.git`
- Configure the server: `cd /home/constellab/Constellab/lab-configurer && bash install_desktop.sh`
- Reboot the computer
- Install [TeamViewer](https://www.teamviewer.com/fr/global/support/knowledge-base/teamviewer-classic/installation/linux/install-teamviewer-classic-on-ubuntu/)

## Start lab manager

- In constellab, create a desktop lab
- Copy the command and execute it in local
- After a few moments, the lab manager should be available at <http://localhost:82>
- Download the configuration file from lab detail page
- Upload the configuration file
- Configure the bricks and start the lab

## Network setup (mDNS)

Configure the local network discovery so the server is reachable via `<hostname>.local` on the LAN without a DNS server.

```bash
cd /home/constellab/Constellab/lab-configurer/edge && sudo bash setup-mdns.sh
```

The script will:

1. Prompt for and set the system hostname
2. Install `avahi-daemon` and `libnss-mdns` if missing
3. Configure Avahi to use IPv4 only
4. Update `/etc/nsswitch.conf` to enable mDNS resolution
5. Enable and restart the Avahi daemon
6. Verify that `<hostname>.local` resolves correctly

After completion, the server will be accessible at `http://<hostname>.local`.