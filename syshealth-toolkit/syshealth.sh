#!/usr/bin/env bash
# ===============================================
# syshealth.sh - System Health & Log Analysis Toolkit
# Lab 1 - Data Collector
# Author: Gannon Strother
# Date: $(date +%Y-%m-%d)
OUTPUT_FILE="$1"
# =============================================

#!/usr/bin/env bash
# ===============================================
# syshealth.sh - System Health & Log Analysis Toolkit
# Lab 3 - Refactoring into Functions
# Author: Your Name
# Date: YYYY-MM-DD
# ===============================================
# --- Thresholds (global, used by multiple functions) ---
CPU_THRESHOLD=75
MEM_THRESHOLD=85
DISK_THRESHOLD=85
# --- Function definitions will go here (print_status, check_*, run_*, parse_*, generate_*) ---

print_status() {
        local status="$1"
        local message="$2"
        if [ "$status" = "OK" ]; then
        echo -e "\e[32m OK: $message\e[0m"
        else
                echo -e "\e[31m ALERT: $message\e[0m"
        fi
}

check_disk_usage() {
	local mount="$1"
	local pct threshold
	threshold="$DISK_THRESHOLD"
	if ! mountpoint -q "$mount" 2>/dev/null && [ "$mount" != "/" ]; then
		print_status "OK" "Mount point $mount does not exist on this system"
		return 0
	fi
	pct=$(df "$mount" | tail -1 | awk '{gsub("%",""); print $5}')
	if (( pct > threshold )); then
		print_status "ALERT" "Disk usage on $mount is ${pct}% (threshold ${threshold}%)"
		return 1
	else
		print_status "OK" "Disk usage on $mount is ${pct}%"
		return 0
	fi
}

check_memory_usage() {
	local pct threshold
	threshold="$MEM_THRESHOLD"
	pct=$(free | awk '/Mem:/ {printf "%.0f", $3/$2*100}')
	if (( pct > threshold )); then
		print_status "ALERT" "Memory usage is ${pct}% (threshold ${threshold}%)"
		return 1
	else
		print_status "OK" "Memory usage is ${pct}%"
		return 0
	fi
}

check_cpu_usage() {
	local pct threshold
	threshold="$CPU_THRESHOLD"
	pct=$(top -bn1 | grep '^%Cpu' | awk '{print 100 - $8}' | cut -d. -f1)
	if (( pct > threshold )); then
		print_status "ALERT" "CPU usage is ${pct}% (threshold ${threshold}%)"
		return 1
	else
		print_status "OK" "CPU usage is ${pct}%"
		return 0
	fi
}

run_health_checks() {
	local overall_status=0
	print_status "CHECK" "Running system health analysis..."
	# Disk checks via loop (replaces the inline for-loop from Lab 2)
	for mount in / /home /var; do
		if ! check_disk_usage "$mount"; then
			overall_status=1
		fi
	done
	# Memory check
	if ! check_memory_usage; then
		overall_status=1
	fi

	# CPU check
	if ! check_cpu_usage; then
		overall_status=1
	fi
	# Store result for generate_report / exit
	HEALTH_STATUS="$overall_status
	return "$overall_status"
}

parse_arguments() {
	OUTPUT_FILE="${1:-}" # if $1 is given, use it as output file; otherwise empty
}






main() {
	# This will be the ONLY code that runs at the top level
	parse_arguments "$@"
	run_health_checks
	generate_report
}

# The single call that starts everything — must be the very last line
main
