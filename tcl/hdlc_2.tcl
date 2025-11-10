# -----------------------------------------------------------------------------
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
# -----------------------------------------------------------------------------
proc split_hex16 {hex16} {
    # Eliminar prefijo "0x" si existe
    set hex16 [string map {"0x" "" "0X" ""} $hex16]

    # Asegurar que tiene 8 caracteres (32 bits)
    set hex16 [format "%04s" $hex16]

    set out {}

    # Saltos de 2 caracteres → 8 bits
    for {set i 0} {$i < 4} {incr i 2} {
        lappend out [string range $hex16 $i [expr {$i+1}]]
    }

    return $out
}
# -----------------------------------------------------------------------------
proc split_hex32 {hex32} {
    # Eliminar prefijo "0x" si existe
    set hex32 [string map {"0x" "" "0X" ""} $hex32]

    # Asegurar que tiene 8 caracteres (32 bits)
    set hex32 [format "%08s" $hex32]

    set out {}

    # Saltos de 2 caracteres → 8 bits
    for {set i 0} {$i < 8} {incr i 2} {
        lappend out [string range $hex32 $i [expr {$i+1}]]
    }

    return $out
}
# -----------------------------------------------------------------------------
proc int2hex16 {value} {
    # Asegurar que el valor está en 16 bits
    set v [expr {$value & 0xFFFF}]
    return [format "%04X" $v]
}
# -----------------------------------------------------------------------------
proc int2hex32 {value} {
    # Asegurar que el valor está en 16 bits
    set v [expr {$value & 0xFFFFFFFF}]
    return [format "%08X" $v]
}
# -----------------------------------------------------------------------------
proc hexByte2bin {hexByte} {
    # Eliminar 0x si viene con prefijo
    set hexByte [string map {"0x" "" "0X" ""} $hexByte]

    # Convertir a entero
    scan $hexByte %x value

    # Convertir a binario de 8 bits
    return [format "%08b" $value]
}
# -----------------------------------------------------------------------------
proc reverse_string {s} {
    set out ""
    set len [string length $s]

    for {set i [expr {$len - 1}]} {$i >= 0} {incr i -1} {
        append out [string index $s $i]
    }

    return $out
}
# -----------------------------------------------------------------------------
proc buffer_to_byte {dir ctrl data} {
    set buffer_byte $dir
    # Anade ctrl to buffer
    lappend buffer_byte  $ctrl
    # Anade data to buffer
    foreach word $data {
        set word_byte [split_hex32 $word]
        foreach b $word_byte {
            lappend buffer_byte 0x$b
        }
    }
    # Calcula el CRC del buffer en bytes
    set crc [crc_ccitt16 $buffer_byte] 
    # Covierte e hex
    set crc_hex [int2hex16 $crc]]
    # Covierte crc_hex a bytes
    set crc_byte [split_hex16 $crc_hex]
    # Anade crc_byte al buffer
    foreach byte $crc_byte {
        lappend buffer_byte 0x$byte
    }
    return $buffer_byte
}
#-----------------------------------------------------------------------------
proc buffer_2_reverse {buffer_byte} {
    set buffer_bin ""
    foreach b $buffer_byte {
        append buffer_bin [reverse_string [format %08b $b]]
    }
    return $buffer_bin
}
#-----------------------------------------------------------------------------
proc bit_stuff_5ones {binStr} {
    set out ""
    set count 0

    foreach c [split $binStr ""] {
        append out $c

        if {$c eq "1"} {
            incr count
        } else {
            set count 0
        }

        # Cuando haya 5 unos seguidos, insertar un 0
        if {$count == 5} {
            append out "0"
            set count 0
        }
    }

    return $out
}
#-----------------------------------------------------------------------------
proc buffer_flag {buffer_bin_stuffing} {
    set buffer_hdlc "01111110"
    append buffer_hdlc $buffer_bin_stuffing
    append buffer_hdlc "01111110"
    return $buffer_hdlc

}
#-----------------------------------------------------------------------------
set dir  0x23
set ctrl 0x1
set data "0xFFFFFFFF 0xAABBCCDD 0X11223344"

# componer packete HDLC en bytes con CRC sin flags
set buffer_byte [buffer_to_byte $dir $ctrl $data]
puts "Buffer byte = $buffer_byte"
# comvert byte to bin y reverse
set buffer_bin [buffer_2_reverse $buffer_byte]
puts "Buffer bin = $buffer_bin"
# add stuffing to buffer
set buffer_bin_stuffing [bit_stuff_5ones $buffer_bin]
puts "Buffer bin stuffing = $buffer_bin_stuffing"
# add flag to buffer
set buffer_hdlc [buffer_flag $buffer_bin_stuffing]
puts "Buffer HDLC = $buffer_hdlc"



