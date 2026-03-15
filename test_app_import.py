import sys
import os

try:
    import apps.zone_owner_portal
    print("SUCCESS: apps.zone_owner_portal imported")
except ImportError as e:
    print(f"FAILURE: apps.zone_owner_portal import failed: {e}")

try:
    from apps.zone_owner_portal.apps import ZoneOwnerPortalConfig
    print(f"SUCCESS: ZoneOwnerPortalConfig found. Name: {ZoneOwnerPortalConfig.name}")
except ImportError as e:
    print(f"FAILURE: ZoneOwnerPortalConfig import failed: {e}")

print(f"Directory exists: {os.path.exists('apps/zone_owner_portal')}")
print(f"Directory contents: {os.listdir('apps/zone_owner_portal') if os.path.exists('apps/zone_owner_portal') else 'N/A'}")
