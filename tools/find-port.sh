#!/bin/bash
# Print the Stick's COM port. It changes across resets, so look it up every time.
source "$(dirname "$0")/env.sh"
"$ARDUINO_CLI" board list --format json 2>/dev/null | tr -d '\r' | python3 -c '
import json,sys
d=json.load(sys.stdin); ports=d.get("detected_ports",d) if isinstance(d,dict) else d
for p in ports:
    port=p.get("port",{}); props=port.get("properties",{})
    if props.get("vid","").lower()=="0x303a": print(port.get("address")); break
'
