set flag "01111110"
set dir 123
set ctrl 0x1
set data "0xFFFFFFFF 0xAABBCCDD"
set buffer [format %08b $dir]
append buffer [format %08b $ctrl]
foreach word [split $data] {
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
set buffer_tx "$flag$buffer_tx$flag" 
puts $buffer
puts $buffer_tx