#!/bin/bash

#  foreground           backgorund
declare -A COLORS=(
    [BLACK]=30         [BG_BLACK]=40
    [RED]=31           [BG_RED]=41
    [GREEN]=32         [BG_GREEN]=42
    [YELLOW]=33        [BG_YELLOW]=43
    [BLUE]=34          [BG_BLUE]=44
    [MAGENTA]=35       [BG_MAGENTA]=45
    [CYAN]=36          [BG_CYAN]=46
    [LIGHT_GRAY]=37    [BG_LIGHT_GRAY]=47
    [GRAY]=90          [BG_GRAY]=100
    [LIGHT_RED]=91     [BG_LIGHT_RED]=101
    [LIGHT_GREEN]=92   [BG_LIGHT_GREEN]=102
    [LIGHT_YELLOW]=93  [BG_LIGHT_YELLOW]=103
    [LIGHT_BLUE]=94    [BG_LIGHT_BLUE]=104
    [LIGHT_MAGENTA]=95 [BG_LIGHT_MAGENTA]=105
    [LIGHT_CYAN]=96    [BG_LIGHT_CYAN]=106
    [WHITE]=97         [BG_WHITE]=107
)

# ${ENDCOLOR}
export ENDCOLOR="\e[0m"

: '
    Ejemplo de uso
    echo -e "$(style bold ${COLORS[RED]})ROJO NEGRITA${RESET}"
'
style() {
    local style=$1    # bold, italic, etc.
    local color_code=$2
    case $style in
        bold)      echo "\e[1;${color_code}m" ;;
        italic)    echo "\e[3;${color_code}m" ;;
        blink)     echo "\e[5;${color_code}m" ;;
        underline) echo "\e[4;${color_code}m" ;;
        dim)       echo "\e[2;${color_code}m" ;;
        *)         echo "\e[0;${color_code}m" ;;
    esac
}