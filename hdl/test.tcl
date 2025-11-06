proc hdlc_composer {dir ctrl data} {
    set flag "01111110"
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
    return "$flag$buffer_tx$flag"
}
set dir 123
set ctrl 0x1
set data "0xFFFFFFFF 0xAABBCCDD 0X11223344"
puts [hdlc_composer $dir $ctrl $data]