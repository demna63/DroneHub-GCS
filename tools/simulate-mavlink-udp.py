#!/usr/bin/env python3
"""Send minimal MAVLink traffic to localhost:14550 for DroneHub GCS HUD smoke tests.

Requires: pip3 install pymavlink
QGC must have AutoConnect UDP enabled (default).
"""
from __future__ import annotations

import sys
import time

try:
    from pymavlink import mavutil
except ImportError:
    print("Install pymavlink first:")
    print("  pip3 install pymavlink")
    sys.exit(1)

HOST = "127.0.0.1"
PORT = 14550
SYSTEM_ID = 1
COMPONENT_ID = 1


def main() -> int:
    print(f"==> MAVLink simulator → udp:{HOST}:{PORT}")
    print("    Open DroneHubGCS (Fly View). Ctrl+C to stop.")
    print()

    conn = mavutil.mavlink_connection(
        f"udpout:{HOST}:{PORT}", source_system=SYSTEM_ID, source_component=COMPONENT_ID
    )

    print("Tip: start DroneHubGCS BEFORE this script (GCS listens on UDP 14550).")
    print("     If PX4 SITL is running, do NOT run this simulator at the same time.")
    print()

    boot_time = time.time()
    seq = 0

    while True:
        now = time.time()
        t_boot_ms = int((now - boot_time) * 1000) & 0xFFFFFFFF

        conn.mav.heartbeat_send(
            mavutil.mavlink.MAV_TYPE_QUADROTOR,
            mavutil.mavlink.MAV_AUTOPILOT_PX4,
            mavutil.mavlink.MAV_MODE_FLAG_CUSTOM_MODE_ENABLED,
            0,
            mavutil.mavlink.MAV_STATE_STANDBY,
        )

        conn.mav.sys_status_send(
            0,
            0,
            0,
            500,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
        )

        conn.mav.global_position_int_send(
            t_boot_ms,
            int(47.400178 * 1e7),
            int(8.542554 * 1e7),
            int(500 * 1000),
            int(520 * 1000),
            0,
            0,
            0,
            0,
        )

        conn.mav.vfr_hud_send(
            0.0,
            3.2,
            0,
            180,
            0,
            0.0,
        )

        conn.mav.battery_status_send(
            0,
            mavutil.mavlink.MAV_BATTERY_FUNCTION_ALL,
            mavutil.mavlink.MAV_BATTERY_TYPE_LIPO,
            12000,
            12600,
            11800,
            100,
            -1,
            [65535, 65535, 65535, 65535, 65535, 65535, 65535, 65535, 65535, 65535],
            mavutil.mavlink.MAV_BATTERY_CHARGE_STATE_OK,
            12,
            25.0,
            0,
        )

        conn.mav.gps_raw_int_send(
            t_boot_ms,
            mavutil.mavlink.GPS_FIX_TYPE_3D_FIX,
            int(47.400178 * 1e7),
            int(8.542554 * 1e7),
            int(520 * 1000),
            65535,
            0,
            0,
            12,
            0,
            0,
            0,
            0,
            0,
        )

        seq += 1
        if seq % 10 == 0:
            print(f"  sent {seq} cycles (heartbeat + position + HUD + battery + GPS)")

        time.sleep(0.5)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        print("\nStopped.")
        raise SystemExit(0)
