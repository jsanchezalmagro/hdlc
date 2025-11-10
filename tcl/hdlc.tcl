% -----------------------------------------------------------------------------
proc hdlc_composer {dir ctrl data} {
    set buffer [format %08b $dir]
    append buffer [format %08b $ctrl]
    foreach word $data {
        append buffer [format %032b [expr {$word}] ]
    }

    set buffer_tx ""
    set cnt 0
    foreach c [split $buffer ""] {
        if {$cnt eq 5} {
            set cnt 0
            append buffer_tx "0"
        } elseif {$c eq "0"} {
            set cnt 0
        } else {
            incr cnt
        }
        append buffer_tx $c
    }
    return $buffer_tx
}
% -----------------------------------------------------------------------------
proc buffer_to_byte {buffer_bin} {
    set grupos [regexp -all -inline {........} $buffer_bin]
    set buffer_byte {}
    foreach g $grupos {
        scan $g %b value
        lappend buffer_byte $value
    }
    return $buffer_byte
}
% -----------------------------------------------------------------------------
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
% -----------------------------------------------------------------------------
proc reverse_string {s} {
    set out ""
    set len [string length $s]

    for {set i [expr {$len - 1}]} {$i >= 0} {incr i -1} {
        append out [string index $s $i]
    }

    return $out
}



set dir 123
set ctrl 0x1
set data "0xFFFFFFFF 0xAABBCCDD 0X11223344"

set buffer_bin [hdlc_composer $dir $ctrl $data]




proc crc_ccitt16 {byteList} {
    set crc 0xFFFF
    set poly 0x1021

    foreach b $byteList {
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

puts [ format %016b [crc_ccitt16 $buffer_int]]