# Copyright (c) 2015, The Board of Trustees of The Leland Stanford Junior 
# University. All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
# 
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
# 
# * Neither the name of copyright holder nor the names of the contributors may 
#   be used to endorse or promote products derived from this software without 
#   specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

source "tcp-common-opt.tcl"

#add/remove packet headers as required
#this must be done before create simulator, i.e., [new Simulator]
#remove-all-packet-headers       ;# removes all except common
#add-packet-header Flags IP RCP  ;#hdrs reqd for RCP traffic

set ns [new Simulator]
puts "Date: [clock format [clock seconds]]"
set sim_start [clock seconds]
puts "Host: [exec uname -a]"

#set trace_file [open qjump.tr w]
#$ns trace-all $trace_file

if {$argc != 43} {
    puts "wrong number of arguments, expected 43, got $argc"
    exit 0
}

set sim_end [lindex $argv 0]
set link_rate [lindex $argv 1]
set mean_link_delay [lindex $argv 2]
set host_delay [lindex $argv 3]
set queueSize [lindex $argv 4]
set load [lindex $argv 5]
set connections_per_pair [lindex $argv 6]
set meanFlowSize [lindex $argv 7]
set paretoShape [lindex $argv 8]
#### Multipath
set enableMultiPath [lindex $argv 9]
set perflowMP [lindex $argv 10]
#### Transport settings options
set sourceAlg [lindex $argv 11] ; # Sack or DCTCP-Sack
set ackRatio [lindex $argv 12]
set enableHRTimer 0
set slowstartrestart [lindex $argv 13]
set DCTCP_g [lindex $argv 14] ; # DCTCP alpha estimation gain
#### Switch side options
set switchAlg [lindex $argv 15]
set DCTCP_K [lindex $argv 16]
# Phantom Queue settings 
set enablePQ [lindex $argv 17]
set PQ_mode [lindex $argv 18]
set PQ_gamma [lindex $argv 19]
set PQ_thresh [lindex $argv 20]
### Pacer settings
set enablePacer [lindex $argv 21]
set TBFsPerServer [lindex $argv 22]
set Pacer_qlength_factor [lindex $argv 23]
set Pacer_rate_ave_factor [lindex $argv 24]
set Pacer_rate_update_interval [lindex $argv 25]
set Pacer_assoc_prob [lindex $argv 26]
set Pacer_assoc_timeout [lindex $argv 27]
#### topology
set topology_spt [lindex $argv 28]
set topology_tors [lindex $argv 29]
set topology_spines [lindex $argv 30]
set topology_x [lindex $argv 31]
#### NAM
set enableNAM [lindex $argv 32]
set min_rto [lindex $argv 33]
set drop_prio_ [lindex $argv 34]
set prio_scheme_ [lindex $argv 35]
set deque_prio_ [lindex $argv 36]
set prob_cap_ [lindex $argv 37]
set keep_order_ [lindex $argv 38]
set enable_dctcp [lindex $argv 39]
set enable_pfabric [lindex $argv 40]
set enable_qjump [lindex $argv 41]
set FLOW_CDF [lindex $argv 42]

#### Packet size is in bytes.
set pktSize 1460
#### trace frequency
set queueSamplingInterval 0.0001
#set queueSamplingInterval 1

puts "Simulation input:"
puts "Dynamic Flow - Pareto"
puts "topology: spines server per rack = $topology_spt, x = $topology_x"
puts "sim_end $sim_end"
puts "link_rate $link_rate Gbps"
puts "link_delay $mean_link_delay sec"
puts "RTT  [expr $mean_link_delay * 2.0 * 6] sec"
puts "host_delay $host_delay sec"
puts "queue size $queueSize pkts"
puts "load $load"
puts "connections_per_pair $connections_per_pair"
puts "enableMultiPath=$enableMultiPath, perflowMP=$perflowMP"
puts "source algorithm: $sourceAlg"
puts "ackRatio $ackRatio"
puts "DCTCP_g $DCTCP_g"
puts "HR-Timer $enableHRTimer"
puts "slow-start Restart $slowstartrestart"
puts "switch algorithm $switchAlg"
puts "DCTCP_K_ $DCTCP_K"
puts "enablePQ $enablePQ"
puts "PQ_mode $PQ_mode"
puts "PQ_gamma $PQ_gamma"
puts "PQ_thresh $PQ_thresh"
puts "enablePacer $enablePacer"
puts "TBFsPerServer $TBFsPerServer"
puts "Pacer_qlength_factor $Pacer_qlength_factor"
puts "Pacer_rate_ave_factor $Pacer_rate_ave_factor"
puts "Pacer_rate_update_interval $Pacer_rate_update_interval"
puts "Pacer_assoc_prob $Pacer_assoc_prob"
puts "Pacer_assoc_timeout $Pacer_assoc_timeout"
puts "pktSize(payload) $pktSize Bytes"
puts "pktSize(include header) [expr $pktSize + 40] Bytes"

puts "enableNAM $enableNAM"
puts " "

################# Transport Options ####################

Agent/TCP set ecn_ 1
Agent/TCP set old_ecn_ 1
Agent/TCP set packetSize_ $pktSize
Agent/TCP/FullTcp set segsize_ $pktSize
Agent/TCP/FullTcp set spa_thresh_ 0
Agent/TCP set window_ 64
Agent/TCP set windowInit_ 2
Agent/TCP set slow_start_restart_ $slowstartrestart
Agent/TCP set windowOption_ 0
Agent/TCP set tcpTick_ 0.000001
Agent/TCP set minrto_ $min_rto
Agent/TCP set maxrto_ 2

Agent/TCP/FullTcp set nodelay_ true; # disable Nagle
Agent/TCP/FullTcp set segsperack_ $ackRatio; 
Agent/TCP/FullTcp set interval_ 0.000006
if {$perflowMP == 0} {  
    Agent/TCP/FullTcp set dynamic_dupack_ 0.75
}
if {$ackRatio > 2} {
    Agent/TCP/FullTcp set spa_thresh_ [expr ($ackRatio - 1) * $pktSize]
}
if {$enableHRTimer != 0} {
    Agent/TCP set minrto_ 0.00100 ; # 1ms
    Agent/TCP set tcpTick_ 0.000001
}
if {[string compare $sourceAlg "DCTCP-Sack"] == 0} {
    Agent/TCP set ecnhat_ true
    Agent/TCPSink set ecnhat_ true
    Agent/TCP set ecnhat_g_ $DCTCP_g;
}
#Shuang
Agent/TCP/FullTcp set prio_scheme_ $prio_scheme_;
Agent/TCP/FullTcp set dynamic_dupack_ 1000000; #disable dupack
Agent/TCP set window_ 1000000
Agent/TCP set windowInit_ 12
Agent/TCP set rtxcur_init_ $min_rto;
Agent/TCP/FullTcp/Sack set clear_on_timeout_ false;
#Agent/TCP/FullTcp set pipectrl_ true;
Agent/TCP/FullTcp/Sack set sack_rtx_threshmode_ 2;
if {$queueSize > 12} {
   Agent/TCP set maxcwnd_ [expr $queueSize - 1];
} else {
   Agent/TCP set maxcwnd_ 12;
}
Agent/TCP/FullTcp set prob_cap_ $prob_cap_;
if {$enable_dctcp != 0} {
    set myAgent "Agent/TCP/FullTcp/Sack";
} else {
    if {$enable_pfabric != 0} {
	set myAgent "Agent/TCP/FullTcp/Sack/MinTCP";
    } else {
	if {$enable_qjump != 0} {
	    set myAgent "Agent/TCP/FullTcp/Sack";
	} else {
	    set myAgent "Agent/TCP/FullTcp/Sack";
	}
    }
}

################# Switch Options ######################

Queue set limit_ $queueSize

Queue/DropTail set queue_in_bytes_ true
Queue/DropTail set mean_pktsize_ [expr $pktSize+40]
Queue/DropTail set drop_prio_ $drop_prio_
Queue/DropTail set deque_prio_ $deque_prio_
Queue/DropTail set keep_order_ $keep_order_

Queue/RED set bytes_ false
Queue/RED set queue_in_bytes_ true
Queue/RED set mean_pktsize_ $pktSize
Queue/RED set setbit_ true
Queue/RED set gentle_ false
Queue/RED set q_weight_ 1.0
Queue/RED set mark_p_ 1.0
Queue/RED set thresh_ $DCTCP_K
Queue/RED set maxthresh_ $DCTCP_K
Queue/RED set drop_prio_ $drop_prio_
Queue/RED set deque_prio_ $deque_prio_
			 
#DelayLink set avoidReordering_ true

if {$enablePQ == 1} {
    Queue/RED set pq_enable_ 1
    Queue/RED set pq_mode_ $PQ_mode ; # 0 = Series, 1 = Parallel
    Queue/RED set pq_drainrate_ [expr $PQ_gamma * $link_rate * 1000000000]
    Queue/RED set pq_thresh_ $PQ_thresh
    #Queue/RED set thresh_ 100000
    #Queue/RED set maxthresh_ 100000
}

################ Pacer Options #######################
if {$enablePacer == 1} {
    TBF set bucket_ [expr 3100 * 8]
    TBF set qlen_ 10000
    TBF set pacer_enable_ 1
    TBF set assoc_timeout_ $Pacer_assoc_timeout
    TBF set assoc_prob_ $Pacer_assoc_prob
    TBF set maxrate_ [expr $link_rate * 1000000000]
    TBF set minrate_ [expr 0.01 * $link_rate * 1000000000]
    TBF set rate_ [expr $link_rate * 1000000000]   
    TBF set qlength_factor_ $Pacer_qlength_factor
    TBF set rate_ave_factor_ $Pacer_rate_ave_factor
    TBF set rate_update_interval_ $Pacer_rate_update_interval    
}
############### NAM ###########################
if {$enableNAM != 0} {
    set namfile [open out.nam w]
    $ns namtrace-all $namfile
}

############## Multipathing ###########################

if {$enableMultiPath == 1} {
    $ns rtproto DV
    Agent/rtProto/DV set advertInterval	[expr 2*$sim_end]  
    Node set multiPath_ 1 
    if {$perflowMP != 0} {
	Classifier/MultiPath set perflow_ 1
    }
}

############# Topoplgy #########################
$ns color 0 Red
$ns color 1 Orange
$ns color 2 Yellow
$ns color 3 Green
$ns color 4 Blue
$ns color 5 Violet
$ns color 6 Brown
$ns color 7 Black

set S [expr $topology_spt * $topology_tors] ; #number of servers
set UCap [expr $link_rate * $topology_spt / $topology_spines / $topology_x] ; #uplink rate

puts "UCap: $UCap" 

for {set i 0} {$i < $S} {incr i} {
    set s($i) [$ns node]
}

for {set i 0} {$i < $topology_tors} {incr i} {
    set n($i) [$ns node]
    $n($i) shape box
    $n($i) color green
}

for {set i 0} {$i < $topology_spines} {incr i} {
    set a($i) [$ns node]
    $a($i) color blue
    $a($i) shape box
}

for {set i 0} {$i < $S} {incr i} {
    set j [expr $i/$topology_spt]
    $ns simplex-link $s($i) $n($j) [set link_rate]Gb [expr $host_delay + $mean_link_delay] $switchAlg     
    $ns simplex-link $n($j) $s($i) [set link_rate]Gb [expr $host_delay + $mean_link_delay] $switchAlg
    $ns duplex-link-op $s($i) $n($j) queuePos -0.5    
    set qfile(s$i,n$j) [$ns monitor-queue $s($i) $n($j) [open queue_s$i\_n$j.tr w] $queueSamplingInterval]
    set qfile(n$j,s$i) [$ns monitor-queue $n($j) $s($i) [open queue_n$j\_s$i.tr w] $queueSamplingInterval]
}

for {set i 0} {$i < $topology_tors} {incr i} {
    for {set j 0} {$j < $topology_spines} {incr j} {
	$ns duplex-link $n($i) $a($j) [set UCap]Gb $mean_link_delay $switchAlg	
	$ns duplex-link-op $n($i) $a($j) queuePos 0.25
    	set qfile(n$i,a$j) [$ns monitor-queue $n($i) $a($j) [open queue_n$i\_a$j.tr w] $queueSamplingInterval]
    	set qfile(a$j,n$i) [$ns monitor-queue $a($j) $n($i) [open queue_a$j\_n$i.tr w] $queueSamplingInterval]
    }
}

##############  Tocken Buckets for Pacer #########
if {$enablePacer == 1} {
    for { set i 0 } { $i < $S } { incr i } {
	for { set j 0 } { $j < $TBFsPerServer} { incr j } {
	    set tbf($s($i),$j) [new TBF]
	} 
    }
} else {
    set tbf 0
}

#############  Agents  #########################
set lambda [expr ($link_rate*$load*1000000000)/($meanFlowSize*8.0/1460*1500)]
#set lambda [expr ($link_rate*$load*1000000000)/($mean_npkts*($pktSize+40)*8.0)]
puts "Arrival: Poisson with inter-arrival [expr 1/$lambda * 1000] ms"
puts "FlowSize: Pareto with mean = $meanFlowSize, shape = $paretoShape"

puts "Setting up connections ..."; flush stdout

set flow_gen 0
set flow_fin 0

set flowlog [open flow.tr w]
set init_fid 0
for {set j 0} {$j < $S } {incr j} {
    for {set i 0} {$i < $S } {incr i} {
	if {$i != $j} {
	    set agtagr($i,$j) [new Agent_Aggr_pair]
	    $agtagr($i,$j) setup $s($i) $s($j) [array get tbf] [expr $j % $TBFsPerServer] "$i $j" $connections_per_pair $init_fid "TCP_pair" $enable_qjump
	    $agtagr($i,$j) attach-logfile $flowlog

	    #puts -nonewline "($i,$j) "
	    #For Poisson/Pareto
	    $agtagr($i,$j) set_PCarrival_process  [expr $lambda/($S - 1)] $FLOW_CDF [expr 17*$i+1244*$j] [expr 33*$i+4369*$j]

	    $ns at 0.1 "$agtagr($i,$j) warmup 0.5 5"
	    $ns at 1 "$agtagr($i,$j) init_schedule"
	    
	    set init_fid [expr $init_fid + $connections_per_pair];
	}
    }
}

puts "Initial agent creation done";flush stdout
puts "Simulation started!"


#############  Queue Monitor   #########################
#set qf [open queue.tr w]
#set qm [$ns monitor-queue $n0 $n1 $qf 0.1]
#$bnecklink queue-sample-timeout

set qstonfile [open qston.tr w]
set qntosfile [open qntos.tr w]

set qlossfile [open qloss.tr w]
set tlossfile [open tloss.tr w]

proc queueTrace {} {
    global ns queueSamplingInterval qfile S topology_spt topology_tors topology_spines 
    global qstonfile qntosfile qlossfile tlossfile 

    set now [$ns now]

    puts -nonewline $qstonfile "$now "
    puts -nonewline $qntosfile "$now "

    for {set k 0} {$k < 20} {incr k} {
        set kdrop_sn($k) 0
    set kdrop_ns($k) 0
    set karrival_sn($k) 0
    set karrival_ns($k) 0
    }

    set ston_drop 0
    set ston_arr 0
    set ston_depart 0
    set ntos_drop 0
    set ntos_arr 0
    set ntos_depart 0

    set bston_drop 0
    set bston_arr 0
    set bston_depart 0
    set bntos_drop 0
    set bntos_arr 0
    set bntos_depart 0

    for {set i 0} {$i < $S} {incr i} {
    set j [expr $i/$topology_spt]

    $qfile(s$i,n$j) instvar barrivals_ bdepartures_ bdrops_ pdrops_ parrivals_ pdepartures_
    puts -nonewline $qstonfile "$barrivals_ $bdepartures_ $bdrops_  "
    incr ston_drop $pdrops_
    incr ston_arr $parrivals_
    incr ston_depart $pdepartures_
    incr bston_drop $bdrops_
    incr bston_arr $barrivals_
    incr bston_depart $bdepartures_

    $qfile(n$j,s$i) instvar barrivals_ bdepartures_ bdrops_ pdrops_ parrivals_ pdepartures_
    puts -nonewline $qntosfile "$barrivals_ $bdepartures_ $bdrops_  "
    incr ntos_drop $pdrops_
    incr ntos_arr $parrivals_
    incr ntos_depart $pdepartures_
    incr bntos_drop $bdrops_
    incr bntos_arr $barrivals_
    incr bntos_depart $bdepartures_

        for {set k 0} {$k < 20} {incr k} {
        set tmp kdrops$k
        set tmp1 karrivals$k
            $qfile(s$i,n$j) instvar $tmp $tmp1
        if {[set $tmp1] != 0} {
        incr kdrop_sn($k) [set $tmp]
        incr karrival_sn($k) [set $tmp1]
        }
            $qfile(n$j,s$i) instvar $tmp $tmp1
        if {[set $tmp1] != 0} {
            incr kdrop_ns($k) [set $tmp]
        incr karrival_ns($k) [set $tmp1]
        }
         }
    }

    for {set k 0} {$k < 20} {incr k} {
        puts $qlossfile "$k $kdrop_sn($k) $karrival_sn($k) $kdrop_ns($k) $karrival_ns($k)"
    }

    set ntoa_drop 0
    set aton_drop 0
    set bntoa_drop 0
    set baton_drop 0
    for {set i 0} {$i < $topology_tors} {incr i} {
	for {set j 0} {$j < $topology_spines} {incr j} {
		$qfile(n$i,a$j) instvar pdrops_ bdrops_
		incr ntoa_drop $pdrops_
		incr bntoa_drop $bdrops_
		$qfile(a$j,n$i) instvar pdrops_ bdrops_
		incr aton_drop $pdrops_
	    	incr baton_drop $bdrops_
	}
    } 

 
 puts $tlossfile "$ston_drop $ntoa_drop $aton_drop  $ntos_drop"
    puts $tlossfile "$ston_drop $ston_arr $ston_depart $ntos_drop $ntos_arr $ntos_depart"

    puts $tlossfile "$bston_drop $bntoa_drop $baton_drop $bntos_drop"
    puts $tlossfile "$bston_drop $bston_arr $bston_depart $bntos_drop $bntos_arr $bntos_depart"

    puts $qstonfile " "
    puts $qntosfile " "

}


$ns run
