import os
import sys
import subprocess
from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/spoof', methods=['POST'])
def spoof_location():
    """Receives incoming coordinates from your map client and forces the system inject."""
    data = request.json
    lat = float(data.get('latitude'))
    lon = float(data.get('longitude'))
    
    try:
        print(f"[!] Processing raw coordinates transmission: Lat {lat}, Lon {lon}")
        
        # Executes the unified location command via the background terminal runner
        cmd = f"pymobiledevice3 developer dvt simulate-location set -- {lat} {lon}"
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        
        if result.returncode == 0:
            print("[+] Target spoof success! Coordinates applied via USB bridge.")
            return jsonify({"status": "success", "lat": lat, "lon": lon}), 200
        else:
            print(f"[-] Apple Injection Error: {result.stderr}")
            return jsonify({"status": "error", "message": result.stderr}), 500
            
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/stop', methods=['POST'])
def stop_spoofing():
    """Clears location overrides and returns control to hardware satellite tracking."""
    try:
        cmd = "pymobiledevice3 developer dvt simulate-location clear"
        subprocess.run(cmd, shell=True)
        print("[*] Position simulation cleared. iPhone reverted to hardware GPS.")
        return jsonify({"status": "success"}), 200
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

if __name__ == '__main__':
    print("[*] Universal Windows-to-iOS Server Engine initialized.")
    print("[*] Listening for iPhone data packets on local port 5000...")
    app.run(host='0.0.0.0', port=5000)
    
# Restarting the cloud compiler build
