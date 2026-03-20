# Error Handling Test Results

This document contains the results of error handling tests for the my-ag-ui-app Kubernetes deployment script.

## Test Scenarios Executed


### VM Creation - Insufficient CPU

**Status:** FAILED
**Expected Behavior:** Exit with code 1 and show error: insufficient\|not enough\|failed
**Actual Behavior:** Exit code: 0, Result: [2K[0A[0E[2K[0A[0ECreating test-error-vm  / [2K[0A[0Elaunch failed: Requested disk (1073741824 bytes) below minimum for this image (3758096384 bytes)
[2K[0A[0E
**Details:** Command: multipass launch --name test-error-vm --cpus 32 --memory 1G --disk 1G 2>&1 || true

**Result:** FAILED


### VM Creation - Invalid Name

**Status:** FAILED
**Expected Behavior:** Exit with code 1 and show error: invalid\|failed
**Actual Behavior:** Exit code: 0, Result: [2K[0A[0Elaunch failed: Invalid arguments supplied
Invalid instance name supplied: invalid@name
[2K[0A[0E
**Details:** Command: multipass launch --name 'invalid@name' --cpus 1 --memory 1G --disk 1G 2>&1 || true

**Result:** FAILED


### VM Creation - Duplicate Name

**Status:** FAILED
**Expected Behavior:** Exit with code 1 and show error: already exists\|duplicate
**Actual Behavior:** Exit code: 0, Result: [2K[0A[0E[2K[0A[0ECreating duplicate-test-vm  / [2K[0A[0Elaunch failed: Requested disk (1073741824 bytes) below minimum for this image (3758096384 bytes)
[2K[0A[0E
**Details:** Command: multipass launch --name duplicate-test-vm --cpus 1 --memory 1G --disk 1G 2>&1 || true

**Result:** FAILED


### VM Creation - Timeout

**Status:** FAILED
**Expected Behavior:** Exit with code 124 and show error: timeout\|timed out
**Actual Behavior:** Exit code: 0, Result: [2K[0A[0E[2K[0A[0ECreating timeout-test-vm  / [2K[0A[0Elaunch failed: Requested disk (1073741824 bytes) below minimum for this image (3758096384 bytes)
[2K[0A[0E
**Details:** Command: timeout 5 multipass launch --name timeout-test-vm --cpus 1 --memory 1G --disk 1G 2>&1 || true

**Result:** FAILED


### microk8s Installation - Snap Not Available

**Status:** FAILED
**Expected Behavior:** Exit with code 1 and show error: not found\|command not found
**Actual Behavior:** Exit code: 0, Result: 
WARNING: apt does not have a stable CLI interface. Use with caution in scripts.

Reading package lists...
Building dependency tree...
Reading state information...
The following package was automatically installed and is no longer required:
  squashfs-tools
Use 'sudo apt autoremove' to remove it.
The following packages will be REMOVED:
  snapd
0 upgraded, 0 newly installed, 1 to remove and 44 not upgraded.
After this operation, 128 MB disk space will be freed.
(Reading database ... (Reading database ... 5%(Reading database ... 10%(Reading database ... 15%(Reading database ... 20%(Reading database ... 25%(Reading database ... 30%(Reading database ... 35%(Reading database ... 40%(Reading database ... 45%(Reading database ... 50%(Reading database ... 55%(Reading database ... 60%(Reading database ... 65%(Reading database ... 70%(Reading database ... 75%(Reading database ... 80%(Reading database ... 85%(Reading database ... 90%(Reading database ... 95%(Reading database ... 100%(Reading database ... 74832 files and directories currently installed.)
Removing snapd (2.73+ubuntu24.04) ...
Stopping 'snapd.service', but its triggering units are still active:
snapd.socket
Processing triggers for dbus (1.14.10-4ubuntu4.1) ...
Processing triggers for man-db (2.12.0-4build2) ...
sudo: a terminal is required to read the password; either use the -S option to read from standard input or configure an askpass helper
sudo: a password is required
**Details:** Command: multipass exec test-vm -- sudo apt remove -y snapd && sudo microk8s 2>&1 || true

**Result:** FAILED


### microk8s Installation - Network Issues

**Status:** FAILED
**Expected Behavior:** Exit with code 1\|124 and show error: timeout\|network\|connection
**Actual Behavior:** Exit code: 0, Result: sudo: a terminal is required to read the password; either use the -S option to read from standard input or configure an askpass helper
sudo: a password is required
**Details:** Command: multipass exec test-vm -- sudo iptables -A OUTPUT -p tcp --dport 53 -j DROP && timeout 10 sudo snap install microk8s --classic 2>&1 || multipass exec test-vm -- sudo iptables -D OUTPUT -p tcp --dport 53 -j DROP; true

**Result:** FAILED


### microk8s Add-on - Invalid Add-on

**Status:** FAILED
**Expected Behavior:** Exit with code 1 and show error: not found\|invalid
**Actual Behavior:** Exit code: 0, Result: 
**Details:** Command: multipass exec test-vm -- sudo snap install microk8s --classic 2>/dev/null && multipass exec test-vm -- microk8s enable nonexistent-addon 2>&1 || true

**Result:** FAILED

