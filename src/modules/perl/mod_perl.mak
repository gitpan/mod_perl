# Microsoft Developer Studio Generated NMAKE File, Format Version 4.20
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Static Library" 0x0104

!IF "$(CFG)" == ""
CFG=perl - Win32 Debug
!MESSAGE No configuration specified.  Defaulting to perl - Win32 Debug.
!ENDIF 

!IF "$(CFG)" != "perl - Win32 Release" && "$(CFG)" != "perl - Win32 Debug"
!MESSAGE Invalid configuration "$(CFG)" specified.
!MESSAGE You can specify a configuration when running NMAKE on this makefile
!MESSAGE by defining the macro CFG on the command line.  For example:
!MESSAGE 
!MESSAGE NMAKE /f "mod_perl.mak" CFG="perl - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "perl - Win32 Release" (based on "Win32 (x86) Static Library")
!MESSAGE "perl - Win32 Debug" (based on "Win32 (x86) Static Library")
!MESSAGE 
!ERROR An invalid configuration is specified.
!ENDIF 

!IF "$(OS)" == "Windows_NT"
NULL=
!ELSE 
NULL=nul
!ENDIF 
################################################################################
# Begin Project
# PROP Target_Last_Scanned "perl - Win32 Debug"
CPP=cl.exe

!IF  "$(CFG)" == "perl - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "Release"
# PROP BASE Intermediate_Dir "Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "Release"
# PROP Intermediate_Dir "Release"
# PROP Target_Dir ""
OUTDIR=.\Release
INTDIR=.\Release

ALL : "$(OUTDIR)\mod_perl.lib"

CLEAN : 
	-@erase "$(INTDIR)\Apache.obj"
	-@erase "$(INTDIR)\config.obj"
	-@erase "$(INTDIR)\Constants.obj"
	-@erase "$(INTDIR)\mod_perl.obj"
	-@erase "$(INTDIR)\perlxsi.obj"
	-@erase "$(OUTDIR)\mod_perl.lib"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

# ADD BASE CPP /nologo /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /YX /c
# ADD CPP /nologo /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /YX /c
CPP_PROJ=/nologo /ML /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_WINDOWS"\
 /Fp"$(INTDIR)/mod_perl.pch" /YX /Fo"$(INTDIR)/" /c 
CPP_OBJS=.\Release/
CPP_SBRS=.\.
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
BSC32_FLAGS=/nologo /o"$(OUTDIR)/mod_perl.bsc" 
BSC32_SBRS= \
	
LIB32=link.exe -lib
# ADD BASE LIB32 /nologo
# ADD LIB32 /nologo
LIB32_FLAGS=/nologo /out:"$(OUTDIR)/mod_perl.lib" 
LIB32_OBJS= \
	"$(INTDIR)\Apache.obj" \
	"$(INTDIR)\config.obj" \
	"$(INTDIR)\Constants.obj" \
	"$(INTDIR)\mod_perl.obj" \
	"$(INTDIR)\perlxsi.obj"

"$(OUTDIR)\mod_perl.lib" : "$(OUTDIR)" $(DEF_FILE) $(LIB32_OBJS)
    $(LIB32) @<<
  $(LIB32_FLAGS) $(DEF_FLAGS) $(LIB32_OBJS)
<<

!ELSEIF  "$(CFG)" == "perl - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "Debug"
# PROP BASE Intermediate_Dir "Debug"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "Debug"
# PROP Intermediate_Dir "Debug"
# PROP Target_Dir ""
OUTDIR=.\Debug
INTDIR=.\Debug

ALL : "$(OUTDIR)\mod_perl.lib"

CLEAN : 
	-@erase "$(INTDIR)\Apache.obj"
	-@erase "$(INTDIR)\config.obj"
	-@erase "$(INTDIR)\Constants.obj"
	-@erase "$(INTDIR)\mod_perl.obj"
	-@erase "$(INTDIR)\perlxsi.obj"
	-@erase "$(OUTDIR)\mod_perl.lib"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

# ADD BASE CPP /nologo /W3 /GX /Z7 /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /YX /c
# ADD CPP /nologo /W3 /GX /Z7 /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /YX /c
CPP_PROJ=/nologo /MLd /W3 /GX /Z7 /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS"\
 /Fp"$(INTDIR)/mod_perl.pch" /YX /Fo"$(INTDIR)/" /c 
CPP_OBJS=.\Debug/
CPP_SBRS=.\.
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
BSC32_FLAGS=/nologo /o"$(OUTDIR)/mod_perl.bsc" 
BSC32_SBRS= \
	
LIB32=link.exe -lib
# ADD BASE LIB32 /nologo
# ADD LIB32 /nologo
LIB32_FLAGS=/nologo /out:"$(OUTDIR)/mod_perl.lib" 
LIB32_OBJS= \
	"$(INTDIR)\Apache.obj" \
	"$(INTDIR)\config.obj" \
	"$(INTDIR)\Constants.obj" \
	"$(INTDIR)\mod_perl.obj" \
	"$(INTDIR)\perlxsi.obj"

"$(OUTDIR)\mod_perl.lib" : "$(OUTDIR)" $(DEF_FILE) $(LIB32_OBJS)
    $(LIB32) @<<
  $(LIB32_FLAGS) $(DEF_FLAGS) $(LIB32_OBJS)
<<

!ENDIF 

.c{$(CPP_OBJS)}.obj:
   $(CPP) $(CPP_PROJ) $<  

.cpp{$(CPP_OBJS)}.obj:
   $(CPP) $(CPP_PROJ) $<  

.cxx{$(CPP_OBJS)}.obj:
   $(CPP) $(CPP_PROJ) $<  

.c{$(CPP_SBRS)}.sbr:
   $(CPP) $(CPP_PROJ) $<  

.cpp{$(CPP_SBRS)}.sbr:
   $(CPP) $(CPP_PROJ) $<  

.cxx{$(CPP_SBRS)}.sbr:
   $(CPP) $(CPP_PROJ) $<  

################################################################################
# Begin Target

# Name "perl - Win32 Release"
# Name "perl - Win32 Debug"

!IF  "$(CFG)" == "perl - Win32 Release"

!ELSEIF  "$(CFG)" == "perl - Win32 Debug"

!ENDIF 

################################################################################
# Begin Source File

SOURCE=.\Apache.c
DEP_CPP_APACH=\
	"..\..\..\..\..\apache-nt\src\conf.h"\
	".\mod_perl.h"\
	{$(INCLUDE)}"\alloc.h"\
	{$(INCLUDE)}"\arpa\inet.h"\
	{$(INCLUDE)}"\av.h"\
	{$(INCLUDE)}"\buff.h"\
	{$(INCLUDE)}"\config.h"\
	{$(INCLUDE)}"\cop.h"\
	{$(INCLUDE)}"\cv.h"\
	{$(INCLUDE)}"\dirent.h"\
	{$(INCLUDE)}"\dosish.h"\
	{$(INCLUDE)}"\embed.h"\
	{$(INCLUDE)}"\EXTERN.h"\
	{$(INCLUDE)}"\form.h"\
	{$(INCLUDE)}"\gv.h"\
	{$(INCLUDE)}"\handy.h"\
	{$(INCLUDE)}"\http_conf_globals.h"\
	{$(INCLUDE)}"\http_config.h"\
	{$(INCLUDE)}"\http_core.h"\
	{$(INCLUDE)}"\http_log.h"\
	{$(INCLUDE)}"\http_main.h"\
	{$(INCLUDE)}"\http_protocol.h"\
	{$(INCLUDE)}"\http_request.h"\
	{$(INCLUDE)}"\httpd.h"\
	{$(INCLUDE)}"\hv.h"\
	{$(INCLUDE)}"\mg.h"\
	{$(INCLUDE)}"\netdb.h"\
	{$(INCLUDE)}"\nostdio.h"\
	{$(INCLUDE)}"\op.h"\
	{$(INCLUDE)}"\opcode.h"\
	{$(INCLUDE)}"\perl.h"\
	{$(INCLUDE)}"\perlio.h"\
	{$(INCLUDE)}"\perlsdio.h"\
	{$(INCLUDE)}"\perlsfio.h"\
	{$(INCLUDE)}"\perly.h"\
	{$(INCLUDE)}"\pp.h"\
	{$(INCLUDE)}"\proto.h"\
	{$(INCLUDE)}"\regex.h"\
	{$(INCLUDE)}"\regexp.h"\
	{$(INCLUDE)}"\scope.h"\
	{$(INCLUDE)}"\scoreboard.h"\
	{$(INCLUDE)}"\sv.h"\
	{$(INCLUDE)}"\sys\socket.h"\
	{$(INCLUDE)}"\sys\stat.h"\
	{$(INCLUDE)}"\sys\types.h"\
	{$(INCLUDE)}"\unixish.h"\
	{$(INCLUDE)}"\util.h"\
	{$(INCLUDE)}"\util_script.h"\
	{$(INCLUDE)}"\win32.h"\
	{$(INCLUDE)}"\win32io.h"\
	{$(INCLUDE)}"\win32iop.h"\
	{$(INCLUDE)}"\XSUB.h"\
	
NODEP_CPP_APACH=\
	"..\..\..\..\..\perl\lib\Core\cw32imp.h"\
	"..\..\..\..\..\perl\lib\Core\os2ish.h"\
	"..\..\..\..\..\perl\lib\Core\plan9\plan9ish.h"\
	"..\..\..\..\..\perl\lib\Core\vmsish.h"\
	

"$(INTDIR)\Apache.obj" : $(SOURCE) $(DEP_CPP_APACH) "$(INTDIR)"


# End Source File
################################################################################
# Begin Source File

SOURCE=.\config.c
DEP_CPP_CONFI=\
	"..\..\..\..\..\apache-nt\src\conf.h"\
	".\mod_perl.h"\
	{$(INCLUDE)}"\alloc.h"\
	{$(INCLUDE)}"\arpa\inet.h"\
	{$(INCLUDE)}"\av.h"\
	{$(INCLUDE)}"\buff.h"\
	{$(INCLUDE)}"\config.h"\
	{$(INCLUDE)}"\cop.h"\
	{$(INCLUDE)}"\cv.h"\
	{$(INCLUDE)}"\dirent.h"\
	{$(INCLUDE)}"\dosish.h"\
	{$(INCLUDE)}"\embed.h"\
	{$(INCLUDE)}"\EXTERN.h"\
	{$(INCLUDE)}"\form.h"\
	{$(INCLUDE)}"\gv.h"\
	{$(INCLUDE)}"\handy.h"\
	{$(INCLUDE)}"\http_conf_globals.h"\
	{$(INCLUDE)}"\http_config.h"\
	{$(INCLUDE)}"\http_core.h"\
	{$(INCLUDE)}"\http_log.h"\
	{$(INCLUDE)}"\http_main.h"\
	{$(INCLUDE)}"\http_protocol.h"\
	{$(INCLUDE)}"\http_request.h"\
	{$(INCLUDE)}"\httpd.h"\
	{$(INCLUDE)}"\hv.h"\
	{$(INCLUDE)}"\mg.h"\
	{$(INCLUDE)}"\netdb.h"\
	{$(INCLUDE)}"\nostdio.h"\
	{$(INCLUDE)}"\op.h"\
	{$(INCLUDE)}"\opcode.h"\
	{$(INCLUDE)}"\perl.h"\
	{$(INCLUDE)}"\perlio.h"\
	{$(INCLUDE)}"\perlsdio.h"\
	{$(INCLUDE)}"\perlsfio.h"\
	{$(INCLUDE)}"\perly.h"\
	{$(INCLUDE)}"\pp.h"\
	{$(INCLUDE)}"\proto.h"\
	{$(INCLUDE)}"\regex.h"\
	{$(INCLUDE)}"\regexp.h"\
	{$(INCLUDE)}"\scope.h"\
	{$(INCLUDE)}"\sv.h"\
	{$(INCLUDE)}"\sys\socket.h"\
	{$(INCLUDE)}"\sys\stat.h"\
	{$(INCLUDE)}"\sys\types.h"\
	{$(INCLUDE)}"\unixish.h"\
	{$(INCLUDE)}"\util.h"\
	{$(INCLUDE)}"\util_script.h"\
	{$(INCLUDE)}"\win32.h"\
	{$(INCLUDE)}"\win32io.h"\
	{$(INCLUDE)}"\win32iop.h"\
	{$(INCLUDE)}"\XSUB.h"\
	
NODEP_CPP_CONFI=\
	"..\..\..\..\..\perl\lib\Core\cw32imp.h"\
	"..\..\..\..\..\perl\lib\Core\os2ish.h"\
	"..\..\..\..\..\perl\lib\Core\plan9\plan9ish.h"\
	"..\..\..\..\..\perl\lib\Core\vmsish.h"\
	

"$(INTDIR)\config.obj" : $(SOURCE) $(DEP_CPP_CONFI) "$(INTDIR)"


# End Source File
################################################################################
# Begin Source File

SOURCE=.\Constants.c
DEP_CPP_CONST=\
	"..\..\..\..\..\apache-nt\src\conf.h"\
	{$(INCLUDE)}"\alloc.h"\
	{$(INCLUDE)}"\arpa\inet.h"\
	{$(INCLUDE)}"\av.h"\
	{$(INCLUDE)}"\buff.h"\
	{$(INCLUDE)}"\config.h"\
	{$(INCLUDE)}"\cop.h"\
	{$(INCLUDE)}"\cv.h"\
	{$(INCLUDE)}"\dirent.h"\
	{$(INCLUDE)}"\dosish.h"\
	{$(INCLUDE)}"\embed.h"\
	{$(INCLUDE)}"\EXTERN.h"\
	{$(INCLUDE)}"\form.h"\
	{$(INCLUDE)}"\gv.h"\
	{$(INCLUDE)}"\handy.h"\
	{$(INCLUDE)}"\http_core.h"\
	{$(INCLUDE)}"\httpd.h"\
	{$(INCLUDE)}"\hv.h"\
	{$(INCLUDE)}"\mg.h"\
	{$(INCLUDE)}"\netdb.h"\
	{$(INCLUDE)}"\nostdio.h"\
	{$(INCLUDE)}"\op.h"\
	{$(INCLUDE)}"\opcode.h"\
	{$(INCLUDE)}"\perl.h"\
	{$(INCLUDE)}"\perlio.h"\
	{$(INCLUDE)}"\perlsdio.h"\
	{$(INCLUDE)}"\perlsfio.h"\
	{$(INCLUDE)}"\perly.h"\
	{$(INCLUDE)}"\pp.h"\
	{$(INCLUDE)}"\proto.h"\
	{$(INCLUDE)}"\regex.h"\
	{$(INCLUDE)}"\regexp.h"\
	{$(INCLUDE)}"\scope.h"\
	{$(INCLUDE)}"\sv.h"\
	{$(INCLUDE)}"\sys\socket.h"\
	{$(INCLUDE)}"\sys\stat.h"\
	{$(INCLUDE)}"\sys\types.h"\
	{$(INCLUDE)}"\unixish.h"\
	{$(INCLUDE)}"\util.h"\
	{$(INCLUDE)}"\win32.h"\
	{$(INCLUDE)}"\win32io.h"\
	{$(INCLUDE)}"\win32iop.h"\
	{$(INCLUDE)}"\XSUB.h"\
	
NODEP_CPP_CONST=\
	"..\..\..\..\..\perl\lib\Core\cw32imp.h"\
	"..\..\..\..\..\perl\lib\Core\os2ish.h"\
	"..\..\..\..\..\perl\lib\Core\plan9\plan9ish.h"\
	"..\..\..\..\..\perl\lib\Core\vmsish.h"\
	

"$(INTDIR)\Constants.obj" : $(SOURCE) $(DEP_CPP_CONST) "$(INTDIR)"


# End Source File
################################################################################
# Begin Source File

SOURCE=.\mod_perl.c
DEP_CPP_MOD_P=\
	"..\..\..\..\..\apache-nt\src\conf.h"\
	".\mod_perl.h"\
	{$(INCLUDE)}"\alloc.h"\
	{$(INCLUDE)}"\arpa\inet.h"\
	{$(INCLUDE)}"\av.h"\
	{$(INCLUDE)}"\buff.h"\
	{$(INCLUDE)}"\config.h"\
	{$(INCLUDE)}"\cop.h"\
	{$(INCLUDE)}"\cv.h"\
	{$(INCLUDE)}"\dirent.h"\
	{$(INCLUDE)}"\dosish.h"\
	{$(INCLUDE)}"\embed.h"\
	{$(INCLUDE)}"\EXTERN.h"\
	{$(INCLUDE)}"\form.h"\
	{$(INCLUDE)}"\gv.h"\
	{$(INCLUDE)}"\handy.h"\
	{$(INCLUDE)}"\http_conf_globals.h"\
	{$(INCLUDE)}"\http_config.h"\
	{$(INCLUDE)}"\http_core.h"\
	{$(INCLUDE)}"\http_log.h"\
	{$(INCLUDE)}"\http_main.h"\
	{$(INCLUDE)}"\http_protocol.h"\
	{$(INCLUDE)}"\http_request.h"\
	{$(INCLUDE)}"\httpd.h"\
	{$(INCLUDE)}"\hv.h"\
	{$(INCLUDE)}"\mg.h"\
	{$(INCLUDE)}"\netdb.h"\
	{$(INCLUDE)}"\nostdio.h"\
	{$(INCLUDE)}"\op.h"\
	{$(INCLUDE)}"\opcode.h"\
	{$(INCLUDE)}"\perl.h"\
	{$(INCLUDE)}"\perlio.h"\
	{$(INCLUDE)}"\perlsdio.h"\
	{$(INCLUDE)}"\perlsfio.h"\
	{$(INCLUDE)}"\perly.h"\
	{$(INCLUDE)}"\pp.h"\
	{$(INCLUDE)}"\proto.h"\
	{$(INCLUDE)}"\regex.h"\
	{$(INCLUDE)}"\regexp.h"\
	{$(INCLUDE)}"\scope.h"\
	{$(INCLUDE)}"\sv.h"\
	{$(INCLUDE)}"\sys\socket.h"\
	{$(INCLUDE)}"\sys\stat.h"\
	{$(INCLUDE)}"\sys\types.h"\
	{$(INCLUDE)}"\unixish.h"\
	{$(INCLUDE)}"\util.h"\
	{$(INCLUDE)}"\util_script.h"\
	{$(INCLUDE)}"\win32.h"\
	{$(INCLUDE)}"\win32io.h"\
	{$(INCLUDE)}"\win32iop.h"\
	{$(INCLUDE)}"\XSUB.h"\
	
NODEP_CPP_MOD_P=\
	"..\..\..\..\..\perl\lib\Core\cw32imp.h"\
	"..\..\..\..\..\perl\lib\Core\os2ish.h"\
	"..\..\..\..\..\perl\lib\Core\plan9\plan9ish.h"\
	"..\..\..\..\..\perl\lib\Core\vmsish.h"\
	

"$(INTDIR)\mod_perl.obj" : $(SOURCE) $(DEP_CPP_MOD_P) "$(INTDIR)"


# End Source File
################################################################################
# Begin Source File

SOURCE=.\mod_perl.h

!IF  "$(CFG)" == "perl - Win32 Release"

!ELSEIF  "$(CFG)" == "perl - Win32 Debug"

!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=.\perlxsi.c
DEP_CPP_PERLX=\
	{$(INCLUDE)}"\av.h"\
	{$(INCLUDE)}"\config.h"\
	{$(INCLUDE)}"\cop.h"\
	{$(INCLUDE)}"\cv.h"\
	{$(INCLUDE)}"\dirent.h"\
	{$(INCLUDE)}"\dosish.h"\
	{$(INCLUDE)}"\embed.h"\
	{$(INCLUDE)}"\EXTERN.h"\
	{$(INCLUDE)}"\form.h"\
	{$(INCLUDE)}"\gv.h"\
	{$(INCLUDE)}"\handy.h"\
	{$(INCLUDE)}"\hv.h"\
	{$(INCLUDE)}"\mg.h"\
	{$(INCLUDE)}"\netdb.h"\
	{$(INCLUDE)}"\nostdio.h"\
	{$(INCLUDE)}"\op.h"\
	{$(INCLUDE)}"\opcode.h"\
	{$(INCLUDE)}"\perl.h"\
	{$(INCLUDE)}"\perlio.h"\
	{$(INCLUDE)}"\perlsdio.h"\
	{$(INCLUDE)}"\perlsfio.h"\
	{$(INCLUDE)}"\perly.h"\
	{$(INCLUDE)}"\pp.h"\
	{$(INCLUDE)}"\proto.h"\
	{$(INCLUDE)}"\regexp.h"\
	{$(INCLUDE)}"\scope.h"\
	{$(INCLUDE)}"\sv.h"\
	{$(INCLUDE)}"\sys\socket.h"\
	{$(INCLUDE)}"\sys\stat.h"\
	{$(INCLUDE)}"\sys\types.h"\
	{$(INCLUDE)}"\unixish.h"\
	{$(INCLUDE)}"\util.h"\
	{$(INCLUDE)}"\win32.h"\
	{$(INCLUDE)}"\win32io.h"\
	{$(INCLUDE)}"\win32iop.h"\
	
NODEP_CPP_PERLX=\
	"..\..\..\..\..\perl\lib\Core\cw32imp.h"\
	"..\..\..\..\..\perl\lib\Core\os2ish.h"\
	"..\..\..\..\..\perl\lib\Core\plan9\plan9ish.h"\
	"..\..\..\..\..\perl\lib\Core\vmsish.h"\
	

"$(INTDIR)\perlxsi.obj" : $(SOURCE) $(DEP_CPP_PERLX) "$(INTDIR)"


# End Source File
# End Target
# End Project
################################################################################
