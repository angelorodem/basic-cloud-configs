import requests
import re
import subprocess
import ipaddress

cmd = ['fail2ban-client', 'set', 'sshd', 'banip']

ips = ""
# tor exit nodes https://check.torproject.org/exit-addresses
#ips += requests.get("https://rules.emergingthreats.net/fwrules/emerging-Block-IPs.txt").text + '\n' # Contains spamhous wich is lots of bogus things
ips += requests.get("https://www.dshield.org/block.txt").text + '\n'
ips += requests.get("http://cinsscore.com/list/ci-badguys.txt").text + '\n'
ips += requests.get("https://lists.blocklist.de/lists/all.txt").text + '\n'

matches = re.findall(r"(\d+\.\d+\.\d+\.0)(/\d+)?", ips)

unique_ips = {}

for match in matches:
    ip, net = match
    
    if net == '':
        if ip.split('.')[2] == "0":
            net = '/16'
        else:
            net = '/24'

    
    if ip+net not in unique_ips:
        unique_ips[ip+net] = 1
    else:
        print("Duplicated IP {}".format(ip+net))

for ip in unique_ips.keys():
   block_cmd = cmd + [ip]
   process = subprocess.Popen(block_cmd, stdout=subprocess.PIPE)
   process.wait()