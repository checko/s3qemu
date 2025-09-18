#!/bin/sh
set -e

# Show available mem sleep states (expect "[s2idle] deep" if S3 is exposed)
cat /sys/power/mem_sleep

# Pick deep (S3)
echo deep > /sys/power/mem_sleep

# Quick ftrace setup to focus on PM paths
mount -t tracefs tracefs /sys/kernel/tracing 2>/dev/null || true
T=/sys/kernel/tracing
echo nop > $T/current_tracer
echo function_graph > $T/current_tracer
# keep noise down; focus on PM entry points
echo > $T/set_ftrace_filter
echo 'pm_*'         >> $T/set_ftrace_filter
echo 'dpm_*'        >> $T/set_ftrace_filter
echo 'suspend_*'    >> $T/set_ftrace_filter
echo 'resume_*'     >> $T/set_ftrace_filter
echo 1 > $T/tracing_on
echo 1 > /sys/power/pm_print_times 2>/dev/null || true

echo "Configured ftrace. Use ./suspend_rtc.sh to test suspend."
