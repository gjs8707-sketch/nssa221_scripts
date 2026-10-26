#!/usr/bin/env bash
# ===============================================
# syshealth.sh - System Health & Log Analysis Toolkit
# Lab 3 - Refactoring into Functions
# Author: Gannon Strother
# Date: 2026-10-5
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
	HEALTH_STATUS="$overall_status"
	return "$overall_status"
}

parse_arguments() {
	OUTPUT_FILE="${1:-}" # if $1 is given, use it as output file; otherwise empty
}


generate_report() {
# Re-collect the human-readable metrics (same as Lab 1)
	local CURRENT_DATE HOSTNAME UPTIME DISK_USAGE MEMORY_USAGE PROCESS_COUNT
	CURRENT_DATE=$(date '+%Y-%m-%d %H:%M:%S')
	HOSTNAME=$(hostname)
	UPTIME=$(uptime -p)
	DISK_USAGE=$(df -h / | tail -1)
	MEMORY_USAGE=$(free -h | awk '/Mem:/ {print $3 "/" $2}')
	PROCESS_COUNT=$(ps -e | wc -l)
	printf "========================================\n"
	printf "System Health Report - %s\n" "$CURRENT_DATE"
	printf "Hostname : %s\n" "$HOSTNAME"
	printf "Uptime : %s\n" "$UPTIME"
	printf "Disk / : %s\n" "$DISK_USAGE"
	printf "Memory used : %s\n" "$MEMORY_USAGE"
	printf "Total processes : %s\n" "$PROCESS_COUNT"
	printf "Health status : %s\n" "$([ "${HEALTH_STATUS:-0}" -eq 0 ] && echo "HEALTHY" || echo "UNHEALTHY - see alerts above")"
	printf "========================================\n"
}


main() {
	parse_arguments "$@"
# Run all health checks (prints colored alerts to terminal)
	run_health_checks
# Generate the structured report (to screen or file)
	if [ -n "$OUTPUT_FILE" ]; then
		generate_report > "$OUTPUT_FILE"
		echo "Report written to $OUTPUT_FILE"
	else
		generate_report
	fi
# Exit with the aggregated health status from run_health_checks
	exit "${HEALTH_STATUS:-0}"
}




# The single call that starts everything — must be the very last line

main "$@"
