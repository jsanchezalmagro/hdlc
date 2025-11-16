package provide agent_hdlc 1.0.0
# -----------------------------------------------------------------------------
package require Itcl
package require agent_common
# -----------------------------------------------------------------------------
## 
#  @brief Namespace with clases and procedures for testing AXI4 Lite-compliant
#         slave modules
#
#     class agent_hdlc
#        method wr_reg  waddr ? wdata ? bresp? --> null
#        method wr_reg_del
#        method rd_reg
#        method rd_reg_del
#
# -----------------------------------------------------------------------------
namespace delete agent_hdlc
namespace eval agent_hdlc {

    itcl::class agent_hdlc {

        # -------------------------
        # Variables privadas
        # -------------------------
        private variable contador 0

        # -------------------------
        # Constructor
        # -------------------------
        constructor {} {
            puts "Objet agent_hdlc create"
        }

        # -----------------------------------------------------------------------------
        private method crc_ccitt16 {buffer_byte} {
            set crc 0xFFFF
            set poly 0x1021

            foreach b $buffer_byte {
                # Asegurar que el valor está entre 0 y 255
                set b [expr {$b & 0xFF}]
                puts $b

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
            puts $crc
            set crc_hex [format "%04X" $crc]
            puts $crc_hex
            set msb "0x[string range $crc_hex 0 1]"
            append buffer_byte [expr {$msb}]
            set lsb "0x[string range $crc_hex 2 3]"
            append buffer_byte [expr {$lsb}]
            return $buffer_byte
        }

        # -----------------------------------------------------------------------------
        private method split_hex16 {hex16} {
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
        private method split_hex32 {hex32} {
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
        private method int2hex16 {value} {
            # Asegurar que el valor está en 16 bits
            set v [expr {$value & 0xFFFF}]

            return [format "%04X" $v]
        }

        # -----------------------------------------------------------------------------
        private method int2hex32 {value} {
            # Asegurar que el valor está en 16 bits
            set v [expr {$value & 0xFFFFFFFF}]

            return [format "%08X" $v]
        }

        # -----------------------------------------------------------------------------
        private method hexByte2bin {hexByte} {
            # Eliminar 0x si viene con prefijo
            set hexByte [string map {"0x" "" "0X" ""} $hexByte]

            # Convertir a entero
            scan $hexByte %x value

            # Convertir a binario de 8 bits
            return [format "%08b" $value]
        }

        # -----------------------------------------------------------------------------
        private method reverse_string {s} {
            set out ""
            set len [string length $s]

            for {set i [expr {$len - 1}]} {$i >= 0} {incr i -1} {
                append out [string index $s $i]
            }

            return $out
        }

        # -----------------------------------------------------------------------------
        private method buffer_to_byte {dir ctrl data} {
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
            # Calcula el CRC del buffer y lo anaes al final bytes
            set buffer_byte [crc_ccitt16 $buffer_byte] 

            return $buffer_byte
        }

        #-----------------------------------------------------------------------------
        private method buffer_2_reverse {buffer_byte} {
            set buffer_bin ""
            foreach b $buffer_byte {
                append buffer_bin [format %08b $b]
            }

            return $buffer_bin
        }

        #-----------------------------------------------------------------------------
        private method bit_stuff_5ones {binStr} {
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
        # -------------------------
        # Método público
        # -------------------------
        public method hdlc_composer {dir ctrl data} {
            # componer packete HDLC en bytes con CRC sin flags
            set buffer_byte [buffer_to_byte $dir $ctrl $data]
            # comvert byte to bin y reverse
            set buffer_bin [buffer_2_reverse $buffer_byte]
            # add stuffing to buffer
            set buffer_bin_stuffing [bit_stuff_5ones $buffer_bin]
            # add flag to buffer
            set buffer_hdlc [buffer_flag $buffer_bin_stuffing]

            return $buffer_hdlc
        }
    }
}

