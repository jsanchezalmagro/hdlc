proc hdlc_split {buffer_hdlc} {
    set frames {}
    set frame ""
    set in_frame 0
    set flag "01111110"
    set flag_len [string length $flag]

    set i 0
    while {$i <= [string length $buffer_hdlc] - $flag_len} {
        set segment [string range $buffer_hdlc $i [expr {$i + $flag_len - 1}]]

        if {$segment eq $flag} {
            if {$in_frame} {
                # End of frame
                lappend frames $frame
                set frame ""
                set in_frame 0
            } else {
                # Start of frame
                set in_frame 1
            }
            incr i $flag_len
        } elseif {$in_frame} {
            append frame [string index $buffer_hdlc $i]
            incr i
        } else {
            incr i
        }
    }

    return $frames
    
}

proc hdlc_unstuffing {frame} {
    set out ""
    set count 0

    foreach c [split $frame ""] {
        if {$c eq "1"} {
            incr count
            append out $c
        } else {
             if {$count == 5} {
                # Skip the next bit (should be a '0')
                set count 0
            } else {
                append out $c
                set count 0
            }
        }
    }

    return $out
}

proc reverse_string {s} {
    set out ""
    set len [string length $s]

    for {set i [expr {$len - 1}]} {$i >= 0} {incr i -1} {
        append out [string index $s $i]
    }

    return $out
}

proc bin2int {binStr} {
    # Eliminar espacios por si vienen
    set clean [string map {" " ""} $binStr]

    # Convertir usando scan
    scan $clean %b value

    return $value
}

proc hdlc_bin2byte {binStr} {
    set bytes {}
    set len [string length $binStr]
    for {set i 0} {$i < $len} {incr i 8} {
        set byte_str [string range $binStr $i [expr {$i + 7}]]
        if {[string length $byte_str] < 8} {
            # Pad with zeros if less than 8 bits
            set byte_str  [string padright $byte_str 8 "0"]
        }
        lappend bytes [bin2int $byte_str]
    }
    return $bytes
}

proc crc_ccitt16 {buffer_byte} {
    set crc 0xFFFF
    set poly 0x1021

    foreach b $buffer_byte {
        # Asegurar que el valor está entre 0 y 255
        set b [expr {$b & 0xFF}]

        # XOR inicial con el byte desplazado
        set crc [expr {$crc ^ ($b << 8)}]

        # Procesar 8 bits
        for {set i 0} {$i < 8} {incr i} {
            if {$crc & 0x8000} {
                set crc [expr {(($crc << 1) ^ $poly) & 0xFFFF}]
            } else {
                set crc [expr {( $crc << 1 ) & 0xFFFF}]
            }
        }
    }

    return [format %016b $crc]
}


::agent_hdlc::agent_hdlc mst

set bb [mst hdlc_composer 0x12 0x23 "0xFFFFFFFF"]
set bbb [hdlc_split $bb]
set bbbb [hdlc_unstuffing $bbb]
set bbbbb [hdlc_bin2byte $bbbb]
set crc [crc_ccitt16 $bbbbb]
puts "CRC: $crc"