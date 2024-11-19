import configparser
import socket
from colorama import Fore, Style, init
import subprocess
import psutil

# Initialize colorama for Windows compatibility
init(autoreset=True)

# Define file paths
server_ini_path = r"C:\Program Files\SF\EDR\agent\config\server.ini"
#For demo
#server_ini_path = r"D:\Users\CTI\My Document\server.ini"
server_port_ini_path = r"C:\Program Files\SF\EDR\agent\config\server_port.ini"

# ANSI color codes for Normal, Warning, and Abnormal
NORMAL = f"{Fore.GREEN}[Normal]{Style.RESET_ALL}"
WARNING = f"{Fore.YELLOW}[Warning]{Style.RESET_ALL}"
ABNORMAL = f"{Fore.RED}[Abnormal]{Style.RESET_ALL}"

# Read server.ini
config_server = configparser.ConfigParser()
config_server.read(server_ini_path)

# Get addr and check UID only if addr is edragent.sangfor.com
addr_ip = config_server.get('config', 'addr', fallback=None)
uid = config_server.get('config', 'uid', fallback=None)

# UID check for 9 digits starting with "9"
def check_uid_format(uid):
    return uid.isdigit() and len(uid) == 9 and uid.startswith("9")

if addr_ip == "edragent.sangfor.com":
    if uid:
        if check_uid_format(uid):
            print(f"CorpID : {uid} {NORMAL}")
        else:
            print(f"CorpID : {uid} {WARNING}")
    else:
        print(f"CorpID : Not Found {ABNORMAL}")
else:
    print("CorpID check skipped (not SaaS ES")

# Function to ping MGR IP
def ping_ip(ip):
    try:
        response = subprocess.run(["ping", "-n", "1", ip], capture_output=True, text=True)
        return response.returncode == 0
    except Exception:
        return False

# Ping the MGR IP
if addr_ip:
    addr_ip_resolved = socket.gethostbyname(addr_ip)  # Resolve hostname to IP if necessary
    if ping_ip(addr_ip_resolved):
        print(f"Ping MGR IP : {addr_ip_resolved} {NORMAL}")
    else:
        print(f"Ping MGR IP : {addr_ip_resolved} {ABNORMAL}")
else:
    print(f"Ping MGR IP : Not Found {ABNORMAL}")

# Read server_port.ini for ports
config_server_port = configparser.ConfigParser()
config_server_port.read(server_port_ini_path)

# Ports to check
ports_to_test = {
    "ipc": config_server_port.getint('port', 'ipc', fallback=None),
    "abs": config_server_port.getint('port', 'abs', fallback=None),
    "agt_download": config_server_port.getint('port', 'agt_download', fallback=None)
}

# Function to test port connectivity
def test_port(ip, port, port_name):
    try:
        with socket.create_connection((ip, port), timeout=5):
            print(f"Test {port_name} port ({port}) {NORMAL}")
    except (socket.timeout, ConnectionRefusedError, OSError):
        print(f"Test {port_name} port ({port}) {ABNORMAL}")

# Test each port on addr IP if available
if addr_ip:
    for port_name, port in ports_to_test.items():
        if port:
            test_port(addr_ip_resolved, port, port_name)
else:
    print("No valid IP address found in 'addr' field in server.ini.")

# Function to check if a specific process is running
def check_process(process_name):
    for proc in psutil.process_iter(['name']):
        if proc.info['name'].lower() == process_name.lower():
            return True
    return False

# List of processes to check
processes = [
    "abs_deployer.exe",
    "ipc_proxy.exe",
    "sfavui.exe",
    "sfavsvc.exe",
    "edr_monitor.exe"
]
print("")
# Check if processes are running
for process in processes:
    if check_process(process):
        print(f"Process {process} {NORMAL}")
    else:
        print(f"Process {process} {ABNORMAL}")
        

input("Press Enter to exit...")