# Microsoft Developer Studio Generated NMAKE File, Based on ApacheModulePerl.dsp
!IF "$(CFG)" == ""
CFG=ApacheModulePerl - Win32 Debug
!MESSAGE No configuration specified. Defaulting to ApacheModulePerl - Win32\
 Debug.
!ENDIF 

!IF "$(CFG)" != "ApacheModulePerl - Win32 Release" && "$(CFG)" !=\
 "ApacheModulePerl - Win32 Debug"
!MESSAGE Invalid configuration "$(CFG)" specified.
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "ApacheModulePerl.mak" CFG="ApacheModulePerl - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "ApacheModulePerl - Win32 Release" (based on\
 "Win32 (x86) Dynamic-Link Library")
!MESSAGE "ApacheModulePerl - Win32 Debug" (based on\
 "Win32 (x86) Dynamic-Link Library")
!MESSAGE 
!ERROR An invalid configuration is specified.
!ENDIF 

!IF "$(OS)" == "Windows_NT"
NULL=
!ELSE 
NULL=nul
!ENDIF 

!IF  "$(CFG)" == "ApacheModulePerl - Win32 Release"

OUTDIR=.\Release
INTDIR=.\Release
# Begin Custom Macros
OutDir=.\Release
# End Custom Macros

!IF "$(RECURSE)" == "0" 

ALL : "$(OUTDIR)\ApacheModulePerl.dll"

!ELSE 

ALL : "$(OUTDIR)\ApacheModulePerl.dll"

!ENDIF 

CLEAN :
	-@erase "$(INTDIR)\Apache.obj"
	-@erase "$(INTDIR)\config.obj"
	-@erase "$(INTDIR)\Constants.obj"
	-@erase "$(INTDIR)\mod_perl.obj"
	-@erase "$(INTDIR)\perlxsi.obj"
	-@erase "$(INTDIR)\vc50.idb"
	-@erase "$(OUTDIR)\ApacheModulePerl.dll"
	-@erase "$(OUTDIR)\ApacheModulePerl.exp"
	-@erase "$(OUTDIR)\ApacheModulePerl.lib"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

CPP=cl.exe
CPP_PROJ=/nologo /MT /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_WINDOWS"\
 /Fp"$(INTDIR)\ApacheModulePerl.pch" /YX /Fo"$(INTDIR)\\" /Fd"$(INTDIR)\\" /FD\
 /c 
CPP_OBJS=.\Release/
CPP_SBRS=.

.c{$(CPP_OBJS)}.obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cpp{$(CPP_OBJS)}.obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cxx{$(CPP_OBJS)}.obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.c{$(CPP_SBRS)}.sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cpp{$(CPP_SBRS)}.sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cxx{$(CPP_SBRS)}.sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

MTL=midl.exe
MTL_PROJ=/nologo /D "NDEBUG" /mktyplib203 /o NUL /win32 
RSC=rc.exe
BSC32=bscmake.exe
BSC32_FLAGS=/nologo /o"$(OUTDIR)\ApacheModulePerl.bsc" 
BSC32_SBRS= \
	
LINK32=link.exe
LINK32_FLAGS=kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib\
 advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib\
 odbccp32.lib /nologo /subsystem:windows /dll /incremental:no\
 /pdb:"$(OUTDIR)\ApacheModulePerl.pdb" /machine:I386\
 /out:"$(OUTDIR)\ApacheModulePerl.dll" /implib:"$(OUTDIR)\ApacheModulePerl.lib" 
LINK32_OBJS= \
	"$(INTDIR)\Apache.obj" \
	"$(INTDIR)\config.obj" \
	"$(INTDIR)\Constants.obj" \
	"$(INTDIR)\mod_perl.obj" \
	"$(INTDIR)\perlxsi.obj" \
	"..\..\..\..\..\..\Apache\ApacheCore.lib" \
	"..\..\..\..\..\..\perl\lib\CORE\perl.lib"

"$(OUTDIR)\ApacheModulePerl.dll" : "$(OUTDIR)" $(DEF_FILE) $(LINK32_OBJS)
    $(LINK32) @<<
  $(LINK32_FLAGS) $(LINK32_OBJS)
<<

!ELSEIF  "$(CFG)" == "ApacheModulePerl - Win32 Debug"

OUTDIR=.\Debug
INTDIR=.\Debug
# Begin Custom Macros
OutDir=.\Debug
# End Custom Macros

!IF "$(RECURSE)" == "0" 

ALL : "$(OUTDIR)\ApacheModulePerl.dll" "$(OUTDIR)\ApacheModulePerl.bsc"

!ELSE 

ALL : "$(OUTDIR)\ApacheModulePerl.dll" "$(OUTDIR)\ApacheModulePerl.bsc"

!ENDIF 

CLEAN :
	-@erase "$(INTDIR)\Apache.obj"
	-@erase "$(INTDIR)\Apache.sbr"
	-@erase "$(INTDIR)\config.obj"
	-@erase "$(INTDIR)\config.sbr"
	-@erase "$(INTDIR)\Constants.obj"
	-@erase "$(INTDIR)\Constants.sbr"
	-@erase "$(INTDIR)\mod_perl.obj"
	-@erase "$(INTDIR)\mod_perl.sbr"
	-@erase "$(INTDIR)\perlxsi.obj"
	-@erase "$(INTDIR)\perlxsi.sbr"
	-@erase "$(INTDIR)\vc50.idb"
	-@erase "$(INTDIR)\vc50.pdb"
	-@erase "$(OUTDIR)\ApacheModulePerl.bsc"
	-@erase "$(OUTDIR)\ApacheModulePerl.dll"
	-@erase "$(OUTDIR)\ApacheModulePerl.exp"
	-@erase "$(OUTDIR)\ApacheModulePerl.ilk"
	-@erase "$(OUTDIR)\ApacheModulePerl.lib"
	-@erase "$(OUTDIR)\ApacheModulePerl.pdb"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

CPP=cl.exe
CPP_PROJ=/nologo /MTd /W3 /Gm /GX /Zi /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS"\
 /FR"$(INTDIR)\\" /Fp"$(INTDIR)\ApacheModulePerl.pch" /YX /Fo"$(INTDIR)\\"\
 /Fd"$(INTDIR)\\" /FD /c 
CPP_OBJS=.\Debug/
CPP_SBRS=.\Debug/

.c{$(CPP_OBJS)}.obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cpp{$(CPP_OBJS)}.obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cxx{$(CPP_OBJS)}.obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.c{$(CPP_SBRS)}.sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cpp{$(CPP_SBRS)}.sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cxx{$(CPP_SBRS)}.sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

MTL=midl.exe
MTL_PROJ=/nologo /D "_DEBUG" /mktyplib203 /o NUL /win32 
RSC=rc.exe
BSC32=bscmake.exe
BSC32_FLAGS=/nologo /o"$(OUTDIR)\ApacheModulePerl.bsc" 
BSC32_SBRS= \
	"$(INTDIR)\Apache.sbr" \
	"$(INTDIR)\config.sbr" \
	"$(INTDIR)\Constants.sbr" \
	"$(INTDIR)\mod_perl.sbr" \
	"$(INTDIR)\perlxsi.sbr"

"$(OUTDIR)\ApacheModulePerl.bsc" : "$(OUTDIR)" $(BSC32_SBRS)
    $(BSC32) @<<
  $(BSC32_FLAGS) $(BSC32_SBRS)
<<

LINK32=link.exe
LINK32_FLAGS=kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib\
 advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib\
 odbccp32.lib /nologo /subsystem:windows /dll /incremental:yes\
 /pdb:"$(OUTDIR)\ApacheModulePerl.pdb" /debug /machine:I386\
 /out:"$(OUTDIR)\ApacheModulePerl.dll" /implib:"$(OUTDIR)\ApacheModulePerl.lib"\
 /pdbtype:sept 
LINK32_OBJS= \
	"$(INTDIR)\Apache.obj" \
	"$(INTDIR)\config.obj" \
	"$(INTDIR)\Constants.obj" \
	"$(INTDIR)\mod_perl.obj" \
	"$(INTDIR)\perlxsi.obj" \
	"..\..\..\..\..\..\Apache\ApacheCore.lib" \
	"..\..\..\..\..\..\perl\lib\CORE\perl.lib"

"$(OUTDIR)\ApacheModulePerl.dll" : "$(OUTDIR)" $(DEF_FILE) $(LINK32_OBJS)
    $(LINK32) @<<
  $(LINK32_FLAGS) $(LINK32_OBJS)
<<

!ENDIF 


!IF "$(CFG)" == "ApacheModulePerl - Win32 Release" || "$(CFG)" ==\
 "ApacheModulePerl - Win32 Debug"
SOURCE=..\perl\Apache.c

!IF  "$(CFG)" == "ApacheModulePerl - Win32 Release"

DEP_CPP_APACH=\
	"..\..\..\..\..\..\apache\src\alloc.h"\
	"..\..\..\..\..\..\apache\src\buff.h"\
	"..\..\..\..\..\..\apache\src\conf.h"\
	"..\..\..\..\..\..\apache\src\http_conf_globals.h"\
	"..\..\..\..\..\..\apache\src\http_config.h"\
	"..\..\..\..\..\..\apache\src\http_core.h"\
	"..\..\..\..\..\..\apache\src\http_log.h"\
	"..\..\..\..\..\..\apache\src\http_main.h"\
	"..\..\..\..\..\..\apache\src\http_protocol.h"\
	"..\..\..\..\..\..\apache\src\http_request.h"\
	"..\..\..\..\..\..\apache\src\httpd.h"\
	"..\..\..\..\..\..\apache\src\multithread.h"\
	"..\..\..\..\..\..\apache\src\nt\readdir.h"\
	"..\..\..\..\..\..\apache\src\regex\regex.h"\
	"..\..\..\..\..\..\apache\src\scoreboard.h"\
	"..\..\..\..\..\..\apache\src\util_script.h"\
	"..\..\..\..\..\..\perl\lib\core\av.h"\
	"..\..\..\..\..\..\perl\lib\core\config.h"\
	"..\..\..\..\..\..\perl\lib\core\cop.h"\
	"..\..\..\..\..\..\perl\lib\core\cv.h"\
	"..\..\..\..\..\..\perl\lib\core\dosish.h"\
	"..\..\..\..\..\..\perl\lib\core\embed.h"\
	"..\..\..\..\..\..\perl\lib\core\extern.h"\
	"..\..\..\..\..\..\perl\lib\core\form.h"\
	"..\..\..\..\..\..\perl\lib\core\gv.h"\
	"..\..\..\..\..\..\perl\lib\core\handy.h"\
	"..\..\..\..\..\..\perl\lib\core\hv.h"\
	"..\..\..\..\..\..\perl\lib\core\mg.h"\
	"..\..\..\..\..\..\perl\lib\core\netdb.h"\
	"..\..\..\..\..\..\perl\lib\core\op.h"\
	"..\..\..\..\..\..\perl\lib\core\opcode.h"\
	"..\..\..\..\..\..\perl\lib\core\perl.h"\
	"..\..\..\..\..\..\perl\lib\core\perlio.h"\
	"..\..\..\..\..\..\perl\lib\core\perlsdio.h"\
	"..\..\..\..\..\..\perl\lib\core\perly.h"\
	"..\..\..\..\..\..\perl\lib\core\pp.h"\
	"..\..\..\..\..\..\perl\lib\core\proto.h"\
	"..\..\..\..\..\..\perl\lib\core\regexp.h"\
	"..\..\..\..\..\..\perl\lib\core\scope.h"\
	"..\..\..\..\..\..\perl\lib\core\sv.h"\
	"..\..\..\..\..\..\perl\lib\core\sys\socket.h"\
	"..\..\..\..\..\..\perl\lib\core\util.h"\
	"..\..\..\..\..\..\perl\lib\core\win32.h"\
	"..\..\..\..\..\..\perl\lib\core\win32io.h"\
	"..\..\..\..\..\..\perl\lib\core\win32iop.h"\
	"..\..\..\..\..\..\perl\lib\core\xsub.h"\
	"..\perl\dirent.h"\
	"..\perl\mod_perl.h"\
	

"$(INTDIR)\Apache.obj" : $(SOURCE) $(DEP_CPP_APACH) "$(INTDIR)"
	$(CPP) $(CPP_PROJ) $(SOURCE)


!ELSEIF  "$(CFG)" == "ApacheModulePerl - Win32 Debug"

DEP_CPP_APACH=\
	"..\..\..\..\..\..\apache\src\alloc.h"\
	"..\..\..\..\..\..\apache\src\buff.h"\
	"..\..\..\..\..\..\apache\src\conf.h"\
	"..\..\..\..\..\..\apache\src\http_conf_globals.h"\
	"..\..\..\..\..\..\apache\src\http_config.h"\
	"..\..\..\..\..\..\apache\src\http_core.h"\
	"..\..\..\..\..\..\apache\src\http_log.h"\
	"..\..\..\..\..\..\apache\src\http_main.h"\
	"..\..\..\..\..\..\apache\src\http_protocol.h"\
	"..\..\..\..\..\..\apache\src\http_request.h"\
	"..\..\..\..\..\..\apache\src\httpd.h"\
	"..\..\..\..\..\..\apache\src\multithread.h"\
	"..\..\..\..\..\..\apache\src\nt\readdir.h"\
	"..\..\..\..\..\..\apache\src\regex\regex.h"\
	"..\..\..\..\..\..\apache\src\scoreboard.h"\
	"..\..\..\..\..\..\apache\src\util_script.h"\
	"..\..\..\..\..\..\perld\lib\core\av.h"\
	"..\..\..\..\..\..\perld\lib\core\config.h"\
	"..\..\..\..\..\..\perld\lib\core\cop.h"\
	"..\..\..\..\..\..\perld\lib\core\cv.h"\
	"..\..\..\..\..\..\perld\lib\core\dirent.h"\
	"..\..\..\..\..\..\perld\lib\core\dosish.h"\
	"..\..\..\..\..\..\perld\lib\core\embed.h"\
	"..\..\..\..\..\..\perld\lib\core\extern.h"\
	"..\..\..\..\..\..\perld\lib\core\form.h"\
	"..\..\..\..\..\..\perld\lib\core\gv.h"\
	"..\..\..\..\..\..\perld\lib\core\handy.h"\
	"..\..\..\..\..\..\perld\lib\core\hv.h"\
	"..\..\..\..\..\..\perld\lib\core\mg.h"\
	"..\..\..\..\..\..\perld\lib\core\netdb.h"\
	"..\..\..\..\..\..\perld\lib\core\op.h"\
	"..\..\..\..\..\..\perld\lib\core\opcode.h"\
	"..\..\..\..\..\..\perld\lib\core\perl.h"\
	"..\..\..\..\..\..\perld\lib\core\perlio.h"\
	"..\..\..\..\..\..\perld\lib\core\perlsdio.h"\
	"..\..\..\..\..\..\perld\lib\core\perly.h"\
	"..\..\..\..\..\..\perld\lib\core\pp.h"\
	"..\..\..\..\..\..\perld\lib\core\proto.h"\
	"..\..\..\..\..\..\perld\lib\core\regexp.h"\
	"..\..\..\..\..\..\perld\lib\core\scope.h"\
	"..\..\..\..\..\..\perld\lib\core\sv.h"\
	"..\..\..\..\..\..\perld\lib\core\sys\socket.h"\
	"..\..\..\..\..\..\perld\lib\core\util.h"\
	"..\..\..\..\..\..\perld\lib\core\win32.h"\
	"..\..\..\..\..\..\perld\lib\core\win32io.h"\
	"..\..\..\..\..\..\perld\lib\core\win32iop.h"\
	"..\..\..\..\..\..\perld\lib\core\xsub.h"\
	"..\perl\dirent.h"\
	"..\perl\mod_perl.h"\
	

"$(INTDIR)\Apache.obj"	"$(INTDIR)\Apache.sbr" : $(SOURCE) $(DEP_CPP_APACH)\
 "$(INTDIR)"
	$(CPP) $(CPP_PROJ) $(SOURCE)


!ENDIF 

SOURCE=..\perl\config.c

!IF  "$(CFG)" == "ApacheModulePerl - Win32 Release"

DEP_CPP_CONFI=\
	"..\..\..\..\..\..\apache\src\alloc.h"\
	"..\..\..\..\..\..\apache\src\buff.h"\
	"..\..\..\..\..\..\apache\src\conf.h"\
	"..\..\..\..\..\..\apache\src\http_conf_globals.h"\
	"..\..\..\..\..\..\apache\src\http_config.h"\
	"..\..\..\..\..\..\apache\src\http_core.h"\
	"..\..\..\..\..\..\apache\src\http_log.h"\
	"..\..\..\..\..\..\apache\src\http_main.h"\
	"..\..\..\..\..\..\apache\src\http_protocol.h"\
	"..\..\..\..\..\..\apache\src\http_request.h"\
	"..\..\..\..\..\..\apache\src\httpd.h"\
	"..\..\..\..\..\..\apache\src\multithread.h"\
	"..\..\..\..\..\..\apache\src\nt\readdir.h"\
	"..\..\..\..\..\..\apache\src\regex\regex.h"\
	"..\..\..\..\..\..\apache\src\util_script.h"\
	"..\..\..\..\..\..\perl\lib\core\av.h"\
	"..\..\..\..\..\..\perl\lib\core\config.h"\
	"..\..\..\..\..\..\perl\lib\core\cop.h"\
	"..\..\..\..\..\..\perl\lib\core\cv.h"\
	"..\..\..\..\..\..\perl\lib\core\dosish.h"\
	"..\..\..\..\..\..\perl\lib\core\embed.h"\
	"..\..\..\..\..\..\perl\lib\core\extern.h"\
	"..\..\..\..\..\..\perl\lib\core\form.h"\
	"..\..\..\..\..\..\perl\lib\core\gv.h"\
	"..\..\..\..\..\..\perl\lib\core\handy.h"\
	"..\..\..\..\..\..\perl\lib\core\hv.h"\
	"..\..\..\..\..\..\perl\lib\core\mg.h"\
	"..\..\..\..\..\..\perl\lib\core\netdb.h"\
	"..\..\..\..\..\..\perl\lib\core\op.h"\
	"..\..\..\..\..\..\perl\lib\core\opcode.h"\
	"..\..\..\..\..\..\perl\lib\core\perl.h"\
	"..\..\..\..\..\..\perl\lib\core\perlio.h"\
	"..\..\..\..\..\..\perl\lib\core\perlsdio.h"\
	"..\..\..\..\..\..\perl\lib\core\perly.h"\
	"..\..\..\..\..\..\perl\lib\core\pp.h"\
	"..\..\..\..\..\..\perl\lib\core\proto.h"\
	"..\..\..\..\..\..\perl\lib\core\regexp.h"\
	"..\..\..\..\..\..\perl\lib\core\scope.h"\
	"..\..\..\..\..\..\perl\lib\core\sv.h"\
	"..\..\..\..\..\..\perl\lib\core\sys\socket.h"\
	"..\..\..\..\..\..\perl\lib\core\util.h"\
	"..\..\..\..\..\..\perl\lib\core\win32.h"\
	"..\..\..\..\..\..\perl\lib\core\win32io.h"\
	"..\..\..\..\..\..\perl\lib\core\win32iop.h"\
	"..\..\..\..\..\..\perl\lib\core\xsub.h"\
	"..\perl\dirent.h"\
	"..\perl\mod_perl.h"\
	

"$(INTDIR)\config.obj" : $(SOURCE) $(DEP_CPP_CONFI) "$(INTDIR)"
	$(CPP) $(CPP_PROJ) $(SOURCE)


!ELSEIF  "$(CFG)" == "ApacheModulePerl - Win32 Debug"

DEP_CPP_CONFI=\
	"..\..\..\..\..\..\apache\src\alloc.h"\
	"..\..\..\..\..\..\apache\src\buff.h"\
	"..\..\..\..\..\..\apache\src\conf.h"\
	"..\..\..\..\..\..\apache\src\http_conf_globals.h"\
	"..\..\..\..\..\..\apache\src\http_config.h"\
	"..\..\..\..\..\..\apache\src\http_core.h"\
	"..\..\..\..\..\..\apache\src\http_log.h"\
	"..\..\..\..\..\..\apache\src\http_main.h"\
	"..\..\..\..\..\..\apache\src\http_protocol.h"\
	"..\..\..\..\..\..\apache\src\http_request.h"\
	"..\..\..\..\..\..\apache\src\httpd.h"\
	"..\..\..\..\..\..\apache\src\multithread.h"\
	"..\..\..\..\..\..\apache\src\nt\readdir.h"\
	"..\..\..\..\..\..\apache\src\regex\regex.h"\
	"..\..\..\..\..\..\apache\src\util_script.h"\
	"..\..\..\..\..\..\perld\lib\core\av.h"\
	"..\..\..\..\..\..\perld\lib\core\config.h"\
	"..\..\..\..\..\..\perld\lib\core\cop.h"\
	"..\..\..\..\..\..\perld\lib\core\cv.h"\
	"..\..\..\..\..\..\perld\lib\core\dirent.h"\
	"..\..\..\..\..\..\perld\lib\core\dosish.h"\
	"..\..\..\..\..\..\perld\lib\core\embed.h"\
	"..\..\..\..\..\..\perld\lib\core\extern.h"\
	"..\..\..\..\..\..\perld\lib\core\form.h"\
	"..\..\..\..\..\..\perld\lib\core\gv.h"\
	"..\..\..\..\..\..\perld\lib\core\handy.h"\
	"..\..\..\..\..\..\perld\lib\core\hv.h"\
	"..\..\..\..\..\..\perld\lib\core\mg.h"\
	"..\..\..\..\..\..\perld\lib\core\netdb.h"\
	"..\..\..\..\..\..\perld\lib\core\op.h"\
	"..\..\..\..\..\..\perld\lib\core\opcode.h"\
	"..\..\..\..\..\..\perld\lib\core\perl.h"\
	"..\..\..\..\..\..\perld\lib\core\perlio.h"\
	"..\..\..\..\..\..\perld\lib\core\perlsdio.h"\
	"..\..\..\..\..\..\perld\lib\core\perly.h"\
	"..\..\..\..\..\..\perld\lib\core\pp.h"\
	"..\..\..\..\..\..\perld\lib\core\proto.h"\
	"..\..\..\..\..\..\perld\lib\core\regexp.h"\
	"..\..\..\..\..\..\perld\lib\core\scope.h"\
	"..\..\..\..\..\..\perld\lib\core\sv.h"\
	"..\..\..\..\..\..\perld\lib\core\sys\socket.h"\
	"..\..\..\..\..\..\perld\lib\core\util.h"\
	"..\..\..\..\..\..\perld\lib\core\win32.h"\
	"..\..\..\..\..\..\perld\lib\core\win32io.h"\
	"..\..\..\..\..\..\perld\lib\core\win32iop.h"\
	"..\..\..\..\..\..\perld\lib\core\xsub.h"\
	"..\perl\dirent.h"\
	"..\perl\mod_perl.h"\
	

"$(INTDIR)\config.obj"	"$(INTDIR)\config.sbr" : $(SOURCE) $(DEP_CPP_CONFI)\
 "$(INTDIR)"
	$(CPP) $(CPP_PROJ) $(SOURCE)


!ENDIF 

SOURCE=..\perl\Constants.c

!IF  "$(CFG)" == "ApacheModulePerl - Win32 Release"

DEP_CPP_CONST=\
	"..\..\..\..\..\..\apache\src\alloc.h"\
	"..\..\..\..\..\..\apache\src\buff.h"\
	"..\..\..\..\..\..\apache\src\conf.h"\
	"..\..\..\..\..\..\apache\src\http_core.h"\
	"..\..\..\..\..\..\apache\src\httpd.h"\
	"..\..\..\..\..\..\apache\src\nt\readdir.h"\
	"..\..\..\..\..\..\apache\src\regex\regex.h"\
	"..\..\..\..\..\..\perl\lib\core\av.h"\
	"..\..\..\..\..\..\perl\lib\core\config.h"\
	"..\..\..\..\..\..\perl\lib\core\cop.h"\
	"..\..\..\..\..\..\perl\lib\core\cv.h"\
	"..\..\..\..\..\..\perl\lib\core\dosish.h"\
	"..\..\..\..\..\..\perl\lib\core\embed.h"\
	"..\..\..\..\..\..\perl