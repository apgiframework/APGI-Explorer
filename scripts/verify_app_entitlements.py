"""Verify the signature and effective permissions of an actual macOS app bundle."""
import argparse
import plistlib
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument('app')
args = parser.parse_args()
subprocess.run(['codesign', '--verify', '--deep', '--strict', args.app], check=True)
result = subprocess.run(['codesign', '-d', '--entitlements', '-', '--xml', args.app],
                        check=True, capture_output=True)
entitlements = plistlib.loads(result.stdout)
for key in ['com.apple.security.app-sandbox', 'com.apple.security.network.client',
            'com.apple.security.files.user-selected.read-write']:
    assert entitlements.get(key) is True, f'Missing effective entitlement: {key}'
for key in ['com.apple.security.files.downloads.read-write', 'com.apple.security.files.pictures.read-write',
            'com.apple.security.temporary-exception.files.absolute-path.read-only',
            'com.apple.security.temporary-exception.mach-lookup.global-name']:
    assert key not in entitlements, f'Unexpected sandbox exception: {key}'
print('Signed app verified: sandbox, outbound networking, user-selected files; no broad exceptions.')
