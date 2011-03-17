ifndef _HDL_TARGETS_
_HDL_TARGETS_=here
# This file is the database of hdl targets and associated tools
# It is a "leaf file" that is used in several places.

# This is the list of top level targets.
# All other targets are some level underneath these
# The levels are: top, family, part, speed

#Testing: HdlTopTargets=xilinx altera verilator test1
HdlTopTargets:=xilinx icarus isim # verilator # altera
HdlTargets_xilinx:=isim virtex5 virtex6
HdlTargets_virtex5:=xc5vlx50t xc5vsx95t xc5vlx330t xc5vlx110t xc5vtx240t
HdlTargets_virtex6:=xc6vlx240t xc6slx45t
#Testing: HdlTargets_test1=test2

HdlSimTools=isim icarus verilator

# Tools are associated with the family or above
HdlToolSet_isim:=isim
HdlToolSet_virtex5:=xst
HdlToolSet_virtex6:=xst
HdlToolSet_verilator:=verilator
HdlToolSet_icarus:=icarus

# Platforms
HdlAllPlatforms:=ml555 schist ml605
HdlPart_ml555:=xc5vlx50t-1-ff1136
HdlPart_schist:=xc5vsx95t-2-ff1136
HdlPart_ml605:=xc6vlx240t-1-ff1156

endif