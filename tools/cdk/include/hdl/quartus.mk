# This file is protected by Copyright. Please refer to the COPYRIGHT file
# distributed with this source distribution.
#
# This file is part of OpenCPI <http://www.opencpi.org>
#
# OpenCPI is free software: you can redistribute it and/or modify it under the
# terms of the GNU Lesser General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# OpenCPI is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
# details.
#
# You should have received a copy of the GNU Lesser General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

# This file has the HDL tool details for altera quartus

include $(OCPI_CDK_DIR)/include/hdl/altera.mk

################################################################################
# $(call HdlToolLibraryFile,target,libname)
# Function required by toolset: return the file to use as the file that gets
# built when the library is built or touched when the library is changed or rebuilt.
#
# For quartus, no precompilation is available, so it is just a directory
# full of links whose name is the name of the library
HdlToolLibraryFile=$2
################################################################################
# Function required by toolset: given a list of targets for this tool set
# Reduce it to the set of library targets.
#
# For quartus, it is generic since there is no processing
HdlToolLibraryTargets=altera
################################################################################
# Variable required by toolset: HdlBin
# What suffix to give to the binary file result of building a core
HdlBin=.qxp
HdlBin_quartus=.qxp
################################################################################
# Variable required by toolset: HdlToolRealCore
# Set if the tool can build a real "core" file when building a core
# I.e. it builds a singular binary file that can be used in upper builds.
# If not set, it implies that only a library containing the implementation is
# possible
HdlToolRealCore=yes
HdlToolRealCore_quartus=yes
################################################################################
# Variable required by toolset: HdlToolNeedBB=yes
# Set if the tool set requires a black-box library to access a core
HdlToolNeedBB=
################################################################################
# Function required by toolset: $(call HdlToolCoreRef,coreref)
# Modify a stated core reference to be appropriate for the tool set
HdlToolCoreRef=$1
HdlToolCoreRef_quartus=$1
################################################################################
# Variable required by toolset: HdlToolNeedsSourceList_<tool>=yes
# Set if the tool requires a listing of source files and libraries
HdlToolNeedsSourceList_quartus=yes
################################################################################
# Function required by toolset: $(call HdlToolLibRef,libname)
# This is the name after library name in a path
# It might adjust (genericize?) the target
#
HdlToolLibRef=$(or $3,$(call HdlGetFamily,$2))

# This is because it seems that Quartus cannot support entities and architectures in 
# separate files, so we have to combine them 
QuartusVHDLWorker=$(and $(findstring worker,$(HdlMode)),$(findstring VHDL,$(HdlLanguage)))
ifdef QuartusVHDLWorkerx
QuartusCombine=$(OutDir)target-$(HdlTarget)/$(Worker)-combine.vhd
QuartusSources=$(filter-out $(Worker).vhd $(ImplHeaderFiles),$(HdlSources)) $(QuartusCombine)
$(QuartusCombine): $(ImplHeaderFiles) $(Worker).vhd
	cat $(ImplHeaderFiles) $(Worker).vhd > $@
else
QuartusSources=$(filter-out %.vh,$(HdlSources))
endif

# Libraries can be built for specific targets, which just is for syntax checking
# Note that a library can be designed for a specific target
QuartusFamily_stratix4:=Stratix IV
QuartusFamily_stratix5:=Stratix V
QuartusMakePart1=$(firstword $1)$(word 3,$1)$(word 2,$1)
QuartusMakePart=$(call QuartusMakePart1,$(subst -, ,$1))

# Make the file that lists the files in order when we are building a library
QuartusMakeExport= \
 $(and $(findstring library,$(HdlMode)), \
   (echo '\#' Source files in order for $(strip \
     $(if $(findstring $(HdlMode),library),library: $(LibName),core: $(Core))); \
    $(foreach s,$(QuartusSources),echo $(notdir $s);) \
   ) > $(LibName)-sources.mk;)

QuartusMakeFamily=$(QuartusFamily_$(call HdlGetFamily,$1))
QuartusMakeDevice=$(strip $(if $(findstring $(HdlMode),platform config container),\
                     $(foreach x,$(call ToUpper,$(call QuartusMakePart,$(HdlPart_$1))),$(xxinfo GOT:$x)$x),\
		     $(xxinfo GOTZ:AUTO:$(HdlMode))AUTO))

# arg 1 is hdltarget arg2 is platform
QuartusMakeDevices=$(infox QMD:$1:$2)\
  echo set_global_assignment -name FAMILY '\"'$(QuartusFamily_$(call HdlGetFamily,$1))'\"'; \
  echo set_global_assignment -name DEVICE \
      $(strip $(if $(findstring $(HdlMode),platform config container),\
                  $(foreach x,$(call ToUpper,$(call QuartusMakePart,$(HdlPart_$2))),$(infox GOT:$x)$x),\
$(if $(HdlExactPart),$(call ToUpper,$(call QuartusMakePart,$(HdlExactPart))),AUTO)));

#		  $(infox GOTZ:AUTO:$(HdlMode))AUTO));


QuartusConstraints=$(or $(HdlConstraints),$(HdlPlatformDir_$1)/$1.qsf)
# Make the settings file
# Note that the local source files use notdir names and search paths while the
# remote libraries use pathnames so that you can have files with the same names.
# FIXME: use of "sed" below is slow - perhaps use .cN rather than _cN? 
#
# We check to see if a core is in 'Cores' before trying to add the
# worker source files (e.g. those underneath gen). The cores listed
# in 'Cores' are either primitive cores or worker-included cores.
QuartusMakeQsf=\
 if test -f $(Core).qsf; then cp $(Core).qsf $(Core).qsf.bak; fi; \
 $(and $(findstring $(HdlMode),library),\
   $(X Fake top module so we can compile libraries anyway for syntax errors) \
   echo 'module onewire(input  W_IN, output W_OUT); assign W_OUT = W_IN; endmodule' > onewire.v;) \
 $(X From here we generate qsf file contents, e.g. "settings") \
 (\
  echo '\#' Common assignments whether a library or a core; \
  $(call QuartusMakeDevices,$(HdlTarget),$(HdlPlatform)) \
  echo set_global_assignment -name TOP_LEVEL_ENTITY $(or $(Top),$(Core)); \
  \
  $(and $(SubCores_$(HdlTarget)),echo '\#' Import QXP file for each core;) \
  $(foreach c,$(SubCores_$(HdlTarget)),$(infox CCC$c)\
    echo set_global_assignment -name QXP_FILE \
      '\"'$(call FindRelative,$(TargetDir),$(call HdlCoreRefMaybeTargetSpecificFile,$c,$(HdlTarget)))'\"';\
    $(if $(filter $c,$(Cores)),\
      $(foreach s,$(call HdlExtractSourcesForLib,$(HdlTarget),$c,$(TargetDir)),\
        echo set_global_assignment -name $(if $(filter vhdl,$(HdlLanguage)),VHDL,VERILOG)_FILE -library $c '\"'$s'\"';),\
      $(foreach w,$(subst _rv,,$(basename $(notdir $c))),$(infox WWW:$w)\
        $(foreach d,$(dir $c),$(infox DDD:$d)\
          $(foreach l,$(if $(filter vhdl,$(HdlLanguage)),vhd,v),$(infox LLLLL:$l)\
            $(foreach f,$(or $(xxcall HdlExists,$d../gen/$w-defs.$l),\
                             $(call HdlExists,$d$w.$l)),$(infox FFFF:$f)\
              echo set_global_assignment -name $(if $(filter vhdl,$(HdlLanguage)),VHDL,VERILOG)_FILE -library $w '\"'$(call FindRelative,$(TargetDir),$f)'\"';\
              $(and $(filter vhdl,$(HdlLanguage)),\
                $(foreach g,$(or $(call HdlExists,$d/generics.vhd),\
                                 $(call HdlExists,$d/$(basename $(notdir $c))-generics.vhd)),\
                  echo set_global_assignment -name VHDL_FILE -library $w '\"'$(call FindRelative,$(TargetDir),$g)'\"';))))))))\
  echo '\# Search path(s) for local files'; \
  $(foreach d,$(call Unique,$(patsubst %/,%,$(dir $(QuartusSources)) $(VerilogIncludeDirs))), \
    echo set_global_assignment -name SEARCH_PATH '\"'$(strip \
     $(call FindRelative,$(TargetDir),$d))'\"';) \
  \
  $(and $(HdlLibrariesInternal),echo '\#' Assignments for adding libraries to search path;) \
  $(foreach l,$(HdlLibrariesInternal),\
    $(foreach hlr,$(call HdlLibraryRefDir,$l,$(HdlTarget),,qts),\
      $(if $(realpath $(hlr)),,$(error No altera library for $l at $(abspath $(hlr))))\
      echo set_global_assignment -name SEARCH_PATH '\"'$(call FindRelative,$(TargetDir),$(hlr))'\"'; \
      $(foreach f,$(wildcard $(hlr)/*_pkg.vhd),\
        echo set_global_assignment -name VHDL_FILE -library $(notdir $l) '\"'$f'\"';\
        $(foreach b,$(subst _pkg.vhd,_body.vhd,$f),\
          $(and $(wildcard $b),\
	     echo set_global_assignment -name VHDL_FILE -library $(notdir $l) '\"'$b'\"';))))) \
  \
  echo '\#' Assignment for local source files using search paths above; \
  $(foreach s,$(QuartusSources), \
    echo set_global_assignment -name $(if $(filter %.vhd,$s),VHDL_FILE -library $(LibName),$(if $(filter %.sv,$s),SYSTEMVERILOG_FILE,VERILOG_FILE)) \
        '\"'$(notdir $s)'\"';) \
  \
  $(if $(findstring $(HdlMode),core worker platform assembly container),\
    echo '\#' Assignments for building cores; \
    echo set_global_assignment -name AUTO_EXPORT_INCREMENTAL_COMPILATION on; \
    echo set_global_assignment -name INCREMENTAL_COMPILATION_EXPORT_FILE $(Core)$(HdlBin); \
    echo set_global_assignment -name INCREMENTAL_COMPILATION_EXPORT_NETLIST_TYPE POST_SYNTH;) \
  $(if $(findstring $(HdlMode),library),\
    echo '\#' Assignments for building libraries; \
    echo set_global_assignment -name SYNTHESIS_EFFORT fast;) \
  $(if $(findstring $(HdlMode),container),\
    echo '\#' Include the platform-related assignments. ;\
    echo source $(call AdjustRelative,$(call QuartusConstraints,$(HdlPlatform)));) \
 ) > $(Core).qsf; echo fit_stratixii_disallow_slm=On > quartus.ini;

# Be safe for now - remove all previous stuff
HdlToolCompile=\
  echo '  'Creating $@ with top == $(Top)\; details in $(TargetDir)/quartus-$(Core).out.;\
  rm -r -f db incremental_db $(Core).qxp $(Core).*.rpt $(Core).*.summary $(Core).qpf $(Core).qsf $(notdir $@); \
  $(QuartusMakeExport) $(QuartusMakeQsf) cat -n $(Core).qsf;\
  set -e; $(call OcpiDbgVar,HdlMode,xc) \
  $(if $(findstring $(HdlMode),core worker platform assembly config container),\
    $(call DoAltera,quartus_map,--write_settings_files=off $(Core),$(Core),map); \
    $(call DoAltera,quartus_cdb,--merge --write_settings_files=off $(Core),$(Core),merge); \
    $(call DoAltera,quartus_cdb,--incremental_compilation_export --write_settings_files=off $(Core),$(Core),export)) \
  $(if $(findstring $(HdlMode),library),\
    $(call DoAltera,quartus_map,--analysis_and_elaboration --write_settings_files=off $(Core),$(Core),map)); \

# When making a library, quartus still wants a "top" since we can't precompile 
# separately from synthesis (e.g. it can't do what vlogcomp can with isim)
# Need to be conditional on libraries
ifeq ($(HdlMode),library)
ifndef Core
Core=onewire
Top=onewire
endif
endif

HdlToolFiles=\
  $(foreach f,$(QuartusSources),\
     $(call FindRelative,$(TargetDir),$(dir $f))/$(notdir $f))

# To create the "library result", we create a directory full of source files
# that have the quartus library directive inserted as the first line to
# force them into the correct library when they are "discovered" via SEARCH_PATH.
ifeq ($(HdlMode),library)
HdlToolPost=\
  if test $$HdlExit = 0; then \
    if ! test -d $(LibName); then \
      mkdir $(LibName); \
    else \
      rm -f $(LibName)/*; \
    fi;\
    for s in $(HdlToolFiles); do \
      if [[ $$s == *.vhd ]]; then \
        echo -- synthesis library $(LibName) | cat - $$s > $(LibName)/`basename $$s`; \
      else \
        ln -s ../$$s $(LibName); \
      fi; \
    done; \
  fi;
endif

BitFile_quartus=$1.sof

QuartusMakeBits=\
	cp $1-top.qsf $1-top.qsf.pre-fit && \
	$(call DoAltera,quartus_map,$1-top,$1-top,map) && \
	$(call DoAltera,quartus_fit,$1-top,$1-top,fit) && \
	cp $1-top.qsf $1-top.qsf.post-fit && \
	$(call DoAltera,quartus_asm,$1-top,$1-top,asm) && \
	cp $1-top.sof $2.sof

# $(call HdlToolDoPlatform,1:<target-dir>,2:<app-name>,3:<app-core-name>,4:<pfconfig>,5:<platform-name>,6: paramconfig)
define HdlToolDoPlatform_quartus
$1/$3.sof: $$(call QuartusConstraints,$5)
	$(AT)echo Building Quartus Bit file: $$@.  Assembly $2 on platform $5 using $4 "($6)".
	$(AT)cd $1 && \
	rm -r -f db incremental_db *-top.* && \
	(echo \# Common assignments whether a library or a core; \
	 echo set_global_assignment -name FAMILY '"'$$(call QuartusMakeFamily,$(HdlPart_$5))'"'; \
	 echo set_global_assignment -name DEVICE $$(call QuartusMakeDevice,$5); \
	 echo set_global_assignment -name TOP_LEVEL_ENTITY $3; \
	 echo set_global_assignment -name QXP_FILE '"'$3.qxp'"'; \
	 echo set_global_assignment -name SDC_FILE '"'$(HdlPlatformDir_$5)/$5.sdc'"'; \
	 echo source $(call AdjustRelative,$(call QuartusConstraints,$5)) \
	 ) > $4-top.qsf && \
	cp $4-top.qsf $4-top.qsf.pre-fit && \
	$(call DoAltera1,quartus_map,$4-top,$4-top,map) && \
	$(call DoAltera1,quartus_fit,$4-top,$4-top,fit) && \
	cp $4-top.qsf $4-top.qsf.post-fit && \
	$(call DoAltera1,quartus_sta,$4-top -c $4-top,$4-top,sta) && \
	$(call DoAltera1,quartus_asm,$4-top,$4-top,asm) && \
	cp $4-top.sof $3.sof

endef
