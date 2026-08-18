import socket
import os

def main():
    hostname = socket.gethostname()
    print(f"Hostname: {hostname}")
    try:
        addrs = socket.getaddrinfo(hostname, None)
        ips = set(addr[4][0] for addr in addrs if ":" not in addr[4][0] and not addr[4][0].startswith("127."))
        print(f"Detected IP Addresses: {list(ips)}")
    except Exception as e:
        print(f"Error getting addrinfo: {e}")

if __name__ == "__main__":
    main()
