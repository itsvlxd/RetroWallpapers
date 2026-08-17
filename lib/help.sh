#!/bin/bash

rx_help_usage() {
    local usage="$1"
    rx_log "info" "Usage: $usage"
    echo ""
}

rx_help_commands() {
    local title="${1:-Commands}"
    echo -e "${PINK}  ${RESET}${title}${GRAY}:${RESET}"
}

rx_help_cmd() {
    local cmd="$1"
    local desc="$2"
    local width="${3:-26}"
    printf " ${PINK}%-${width}s${GRAY}- ${RESET}%s\n" "$cmd" "$desc"
}

rx_help_example() {
    local cmd="$1"
    local desc="$2"
    local width="${3:-26}"
    printf " ${GRAY}%-${width}s${RESET} %s\n" "$cmd" "$desc"
}

rx_help_spacer() {
    echo ""
}

rx_help_examples() {
    echo -e ""
    echo -e "${PINK} ${RESET}Examples${GRAY}:${RESET}"
}

rx_help_section() {
    local icon="${1:-󰇝}"
    local title="$2"
    echo -e " ${PINK}${icon} ${RESET}${title}${GRAY}:${RESET}"
}

rx_help_option() {
    local cmd="$1"
    local desc="$2"
    printf " ${PINK}%-24s${GRAY} %s${RESET}\n" "$cmd" "$desc"
}

rx_help_separator() {
    echo -e " ${PINK}󰇝${MUTE} ───────────────────────────────────────${RESET}"
}

rx_help_header() {
    local icon="$1"
    local title="$2"
    echo -e "\n ${PINK}$icon  ${title}${RESET}"
    rx_help_separator
}

rx_help_footer() {
    rx_help_separator
    echo ""
}

rx_help_wrap() {
    local text="$1"
    local width="${2:-50}"
    echo "$text" | fold -s -w "$width" | while read -r line; do
        echo -e " ${GRAY}$line${RESET}"
    done
}

rx_table_separator() {
    echo -e " ${PINK}󰇝${MUTE} ───────────────────────────────────────${RESET}"
}

rx_table_header() {
    local icon="$1"
    local title="$2"
    echo -e "\n ${PINK}$icon ${title}${RESET}"
    rx_table_separator
}

rx_table_row() {
    local icon="$1"
    local label="$2"
    local value="$3"
    local value_color="${4:-$PINK}"
    local width="${5:-26}"
    printf " ${PINK}${icon}${RESET} %-${width}s ${value_color}%s${RESET}\n" "$label" "$value"
}

rx_table_row_gray() {
    local icon="$1"
    local label="$2"
    local value="$3"
    local width="${4:-$DEFAULT_TABLE_WIDTH}"
    printf " ${PINK}${icon}${RESET} %-${width}s ${GRAY}%s${RESET}\n" "$label" "$value"
}

rx_table_key_value() {
    local label="$1"
    local value="$2"
    local value_color="${3:-$PINK}"
    local width="${4:-$DEFAULT_TABLE_WIDTH}"
    printf " ${PINK}󰄾${RESET} %-${width}s ${value_color}%s${RESET}\n" "$label" "$value"
}

rx_table_simple() {
    local icon="$1"
    local value="$2"
    local value_color="${3:-$PINK}"
    printf " ${PINK}${icon}${RESET} ${value_color}%s${RESET}\n" "$value"
}

rx_table_spacer() {
    echo ""
}

rx_table_list_header() {
    local icon="$1"
    local col1="$2"
    local col2="$3"
    local col3="$4"
    printf " ${PINK}${icon}${RESET} %-30s ${PINK}%-12s${RESET} %s${RESET}\n" "$col1" "$col2" "${col3:- }"
}

rx_table_list_row() {
    local icon="$1"
    local col1="$2"
    local col2="$3"
    local col3="$4"
    local col1_color="${5:-$PINK}"
    local col2_color="${6:-$GRAY}"
    local col3_color="${7:-$MUTE}"
    printf " ${col1_color}${icon}${RESET} %-30s ${col2_color}%-12s${RESET} ${col3_color}%s${RESET}\n" "$col1" "$col2" "${col3:- }"
}

rx_table_list_single() {
    local icon="$1"
    local text="$2"
    local text_color="${3:-$PINK}"
    printf " ${PINK}${icon}${RESET} ${text_color}%s${RESET}\n" "$text"
}

# Read a line from the controlling terminal when available, otherwise from
# stdin. This keeps prompts working even when the surrounding loop has its
# stdin redirected (e.g. `while ... done < <(git ...)`).
_rx_read() {
    local var="$1"
    if [[ -e /dev/tty ]]; then
        if read -r "$var" </dev/tty; then
            return 0
        fi
    fi
    read -r "$var"
}

rx_confirm() {
    local message="$1"
    local default="${2:-N}"
    local skip="${3:-false}"

    if [[ $skip == "true" || ${RX_SETUP_YES:-false} == "true" || ${SKIP_PROMPT:-false} == "true" ]]; then
        return 0
    fi

    if [[ $default == "Y" ]]; then
        rx_log "info" "${message} ${PINK}[Y/n]${RESET}: "
    else
        rx_log "info" "${message} ${PINK}[y/N]${RESET}: "
    fi

    local confirm
    _rx_read confirm
    [[ -z $confirm ]] && confirm="$default"

    if [[ $confirm =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

rx_yesno() {
    local message="$1"
    local result

    if [[ ${SKIP_PROMPT:-false} == "true" || ${RX_SETUP_YES:-false} == "true" ]]; then
        return 0
    fi

    rx_log "info" "${message} ${PINK}[y/N]${RESET}: "
    _rx_read result

    [[ $result =~ ^[Yy]$ ]]
}

rx_input() {
    local label="$1"
    local default="${2:-}"
    local pattern="${3:-}"
    local error_msg="${4:-Invalid input}"

    if [[ ${SKIP_PROMPT:-false} == "true" || ${RX_SETUP_YES:-false} == "true" ]]; then
        echo "$default"
        return 0
    fi

    while true; do
        rx_log "info" "${label} ${MUTE}[${default}]${RESET}: "

        local input
        _rx_read input

        [[ -z $input ]] && input="$default"

        if [[ -n $pattern ]]; then
            if [[ ! $input =~ $pattern ]]; then
                rx_log "error" "${error_msg}"
                continue
            fi
        fi

        echo "$input"
        return 0
    done
}
