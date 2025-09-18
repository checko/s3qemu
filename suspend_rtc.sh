#!/bin/sh
set -e

# Arm RTC to wake in N seconds (default 5)
SEC="${1:-5}"

# Clear existing wakealarm
echo 0 > /sys/class/rtc/rtc0/wakealarm
# Set relative wake
echo "+$SEC" > /sys/class/rtc/rtc0/wakealarm

# Optional: narrow pm_test phase while learning (uncomment one)
# echo devices   > /sys/power/pm_test
# echo platform  > /sys/power/pm_test
# echo processors> /sys/power/pm_test
# echo core      > /sys/power/pm_test

echo "Suspending to deep for ~${SEC}s ..."
echo mem > /sys/power/state

# After resume, grab the trace to /tmp and show a short summary
T=/sys/kernel/tracing
echo 0 > $T/tracing_on
cat $T/trace > /tmp/pm.trace
echo "Resume done. Trace saved to /tmp/pm.trace"
grep -E 'suspend_enter|resume_resume|pm_suspend|suspend_devices_and_enter|dpm_' /tmp/pm.trace | head -50 || true

