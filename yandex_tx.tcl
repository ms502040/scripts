#!/usr/bin/tclsh

#
# This Tcl script uses the Yandex Translate APIs to translate a line into all possile supported languages.
#
# N.B.: Tested on Tcl 8.5 and 8.6 only
#
# To run this script:
#
# Generate a Yandex.Translate API: http://api.yandex.com/translate/
#
# chdmod +x yandex_tx.tcl
# ./yandex_tx.tcl <yandex_api_key> <lang_code> <text_line>
#
# example:
# ./yandex_tx.tcl trnsl.1.1.2012030100000.S.123123123.123123123 en 'This will cost you $0.0 !'
#


package require http
package require tls
package require tdom

::http::register https 443 ::tls::socket

if {$argc < 3} {
    puts "usage: yandex_tx.tcl <yandex_api_key> <lang_code> <text>"
    exit 1
}

set yandex_api_key    [lindex $argv 0] 
set translate_from    [lindex $argv 1]
set text_to_translate [lindex $argv 2]

array set lang_array []
set lang_api_url "https://translate.yandex.net/api/v1.5/tr/getLangs?key=$yandex_api_key&ui=en"
set tx_base_url "https://translate.yandex.net/api/v1.5/tr/translate?key=$yandex_api_key&lang="
set translated_into [list]
set translations    [list]

proc urlEncode {str} {
    set uStr [encoding convertto utf-8 $str]
    set chRE {[^-A-Za-z0-9._~\n]};
    set replacement {%[format "%02X" [scan "\\\0" "%c"]]}
    return [string map {"\n" "%0A"} [subst [regsub -all $chRE $uStr $replacement]]]
}


# get the list of all code languages currently supported by Yandex
http::config -useragent "Mozilla"
set http  [::http::geturl $lang_api_url]
set html  [::http::data $http]

set doc [dom parse $html]
set root [$doc documentElement]

foreach textNode [$root childNodes] {
    if {[$textNode nodeName] == "langs"} {
        foreach itemNode [$textNode childNodes] {
            set key   [$itemNode getAttribute "key"]
            set value [$itemNode getAttribute "value"]
            set lang_array($key) $value
        }
    }
}

#parray lang_array


# Tcl 8.6: foreach {lang_code desc} [lsort -stride 2 -index 1 -ascii [array get lang_array]]
# but for backward compatibility:
set x [list]
foreach {k v} [array get lang_array] {
    lappend x [list $k $v]
}
set lang_list [lsort -ascii -index 1 $x]


foreach lang_to $lang_list {
    
    set lang_code [lindex $lang_to 0]
    set url ""
    append url $tx_base_url "$translate_from-$lang_code" 
    append url "&text=[urlEncode $text_to_translate]"

    set http  [::http::geturl $url]
    set html  [::http::data $http]

    set doc  [dom parse $html]
    set root [$doc documentElement]

    foreach textNode [$root childNodes] {

        if {[$textNode nodeName] == "text"} {
            set tx [$textNode text]
            lappend translated_into $lang_array($lang_code)
            lappend translations  $tx
            puts "$lang_array($lang_code): $tx"
        }
    }
}
        
        
puts "\n\nTRANSLATED INTO: $translated_into\n\n"

foreach line $translations {
    puts $line\n
}

