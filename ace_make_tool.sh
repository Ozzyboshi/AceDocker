#!/bin/bash

if [ $# -lt 2 ]
  then
    echo "usage:"
    echo "ace_make_tool dir projectname type"
    echo ""
    echo "type:"
    echo "	rawcop"
    echo "	copblock"
    exit 1
fi

DIR=$1
PROJECTNAME=$2
PROJECTTYPE=$3

#if [[ $PROJECTTYPE != "rawcop"]] && [[ $PROJECTTYPE != "copblock"]]
#	echo "Type not correct, must be rawcop or copblock"
#	exit 1
#fi

if ! [[ "$PROJECTTYPE" =~ ^(copblock|rawcop)$ ]] 
then
  echo "Type not correct, must be rawcop or copblock"
  exit 1
fi 

if [ -d "$DIR" ]; then
  # Take action if $DIR exists. #
  echo "Dir ${DIR} already exists... exiting ..."
  exit 1
fi

if mkdir -p "$DIR" ; then
    echo "Dir ${DIR} created ..."
else
    echo "Cant create Dir ${DIR} exiting ..."
    exit 1 
fi

SRCDIR=${DIR}/src
if mkdir -p "$SRCDIR" ; then
    echo "Dir ${SRCDIR} created ..."
else
    echo "Cant create Dir ${SRCDIR} exiting ..."
    exit 1 
fi

RESDIR=${DIR}/_res
if mkdir -p "$RESDIR" ; then
    echo "Dir ${RESDIR} created ..."
else
    echo "Cant create Dir ${RESDIR} exiting ..."
    exit 1 
fi

echo "
#include <ace/managers/state.h>

#define GAME_STATE_COUNT 1

extern tStateManager *g_pGameStateManager;
extern tState *g_pGameStates[];
" >> ${SRCDIR}/main.h
echo "${SRCDIR}/main.h created"

echo "
#include <ace/generic/main.h>
#include <ace/managers/key.h>
#include <ace/managers/state.h>

#include \"main.h\"
#include \"${PROJECTNAME}.h\"

tStateManager *g_pGameStateManager = 0;
tState *g_pGameStates[GAME_STATE_COUNT] = {0};

void genericCreate(void) 
{
  // Here goes your startup code
    logWrite(\"Hello, Amiga!\n\");
      keyCreate(); // We'll use keyboard
      g_pGameStateManager = stateManagerCreate();
      g_pGameStates[0] = stateCreate(${PROJECTNAME}GsCreate, ${PROJECTNAME}GsLoop, ${PROJECTNAME}GsDestroy, 0, 0, 0);
      statePush(g_pGameStateManager, g_pGameStates[0]);
}

void genericProcess(void) 
{
    // Here goes code done each game frame
      keyProcess();
      stateProcess(g_pGameStateManager);
}

void genericDestroy(void) 
{
  // Here goes your cleanup code
  
  stateManagerDestroy(g_pGameStateManager);
  stateDestroy(g_pGameStates[0]);
  
  keyDestroy(); // We don't need it anymore
  logWrite(\"Goodbye, Amiga!\n\");
}
" >> ${SRCDIR}/main.c
echo "${SRCDIR}/main.c created"

if [ $PROJECTTYPE == "copblock" ] 
then

echo "#include \"${PROJECTNAME}.h\"
#include <ace/managers/key.h> // Keyboard processing
#include <ace/managers/game.h> // For using gameExit
#include <ace/managers/system.h> // For systemUnuse and systemUse
#include <ace/managers/viewport/simplebuffer.h> // Simple buffer

// All variables outside fns are global - can be accessed in any fn
// Static means here that given var is only for this file, hence 's_' prefix
// You can have many variables with same name in different files and they'll be
// independent as long as they're static
// * means pointer, hence 'p' prefix
static tView *s_pView; // View containing all the viewports
static tVPort *s_pVpScore; // Viewport for score
static tSimpleBufferManager *s_pScoreBuffer;
static tVPort *s_pVpMain; // Viewport for playfield
static tSimpleBufferManager *s_pMainBuffer;

void ${PROJECTNAME}GsCreate(void) {
  // Create a view - first arg is always zero, then it's option-value
  s_pView = viewCreate(0,
    TAG_VIEW_GLOBAL_CLUT, 1, // Same Color LookUp Table for all viewports
  TAG_END); // Must always end with TAG_END or synonym: TAG_DONE

  // Viewport for score bar - on top of screen
  s_pVpScore = vPortCreate(0,
    TAG_VPORT_VIEW, s_pView, // Required: specify parent view
    TAG_VPORT_BPP, 2, // Optional: 2 bits per pixel, 4 colors
    TAG_VPORT_HEIGHT, 32, // Optional: let's make it 32px high
  TAG_END); // same syntax as view creation

  // Create simple buffer manager with bitmap exactly as large as viewport
  s_pScoreBuffer = simpleBufferCreate(0,
    TAG_SIMPLEBUFFER_VPORT, s_pVpScore, // Required: parent viewport
    // Optional: buffer bitmap creation flags
    // we'll use them to initially clear the bitmap
    TAG_SIMPLEBUFFER_BITMAP_FLAGS, BMF_CLEAR,
  TAG_END);

  // Now let's do the same for main playfield
  s_pVpMain = vPortCreate(0,
    TAG_VPORT_VIEW, s_pView,
    TAG_VPORT_BPP, 4, // 2 bits per pixel, 4 colors
    // We won't specify height here - viewport will take remaining space.
  TAG_END);
  s_pMainBuffer = simpleBufferCreate(0,
    TAG_SIMPLEBUFFER_VPORT, s_pVpMain, // Required: parent viewport
    TAG_SIMPLEBUFFER_BITMAP_FLAGS, BMF_CLEAR,
  TAG_END);

  // Since we've set up global CLUT, palette will be loaded from first viewport
  // Colors are 0x0RGB, each channel accepts values from 0 to 15 (0 to F).
  s_pVpScore->pPalette[0] = 0x0000; // First color is also border color
  s_pVpScore->pPalette[1] = 0x0888; // Gray
  s_pVpScore->pPalette[2] = 0x0800; // Red - not max, a bit dark
  s_pVpScore->pPalette[3] = 0x0008; // Blue - same brightness as red

  // We don't need anything from OS anymore
  systemUnuse();

  // Load the view
  viewLoad(s_pView);
}

void ${PROJECTNAME}GsLoop(void) {
  // This will loop forever until you \"pop\" or change gamestate
  // or close the game
  if(keyCheck(KEY_ESCAPE)) {
    gameExit();
    return ;
  }
  
  vPortWaitForEnd(s_pVpMain);
}

void ${PROJECTNAME}GsDestroy(void) {
  // Cleanup when leaving this gamestate
  systemUse();

  // This will also destroy all associated viewports and viewport managers
  viewDestroy(s_pView);
}" >> ${SRCDIR}/${PROJECTNAME}.c
echo "${SRCDIR}/${PROJECTNAME}.c created"

else

echo "#include \"${PROJECTNAME}.h\"
#include <ace/managers/key.h> // Keyboard processing
#include <ace/managers/game.h> // For using gameExit
#include <ace/managers/system.h> // For systemUnuse and systemUse
#include <ace/managers/viewport/simplebuffer.h> // Simple buffer

#define BITPLANES 4

// All variables outside fns are global - can be accessed in any fn
// Static means here that given var is only for this file, hence 's_' prefix
// You can have many variables with same name in different files and they'll be
// independent as long as they're static
// * means pointer, hence 'p' prefix
static tView *s_pView; // View containing all the viewports
static tVPort *s_pVpMain; // Viewport for playfield
static tSimpleBufferManager *s_pMainBuffer;
static UWORD s_uwCopRawOffs=0;
static tCopCmd *pCopCmds;

void ${PROJECTNAME}GsCreate(void) {
  ULONG ulRawSize = (simpleBufferGetRawCopperlistInstructionCount(BITPLANES) +
                 32 * 3 + // 32 bars - each consists of WAIT + 2 MOVE instruction
                 1 +      // Final WAIT
                 1        // Just to be sure
    );
    
  // Create a view - first arg is always zero, then it's option-value
  s_pView = viewCreate(0,
    TAG_VIEW_GLOBAL_CLUT, 1, // Same Color LookUp Table for all viewports
    TAG_VIEW_COPLIST_MODE, VIEW_COPLIST_MODE_RAW, 
    TAG_VIEW_COPLIST_RAW_COUNT, ulRawSize,
  TAG_END); // Must always end with TAG_END or synonym: TAG_DONE

  // Now let's do the same for main playfield
  s_pVpMain = vPortCreate(0,
    TAG_VPORT_VIEW, s_pView,
    TAG_VPORT_BPP, BITPLANES, // 4 bits per pixel, 16 colors
    // We won't specify height here - viewport will take remaining space.
  TAG_END);
  s_pMainBuffer = simpleBufferCreate(0,
    TAG_SIMPLEBUFFER_VPORT, s_pVpMain, // Required: parent viewport
    TAG_SIMPLEBUFFER_BITMAP_FLAGS, BMF_CLEAR,
    TAG_SIMPLEBUFFER_COPLIST_OFFSET, 0, 
    TAG_SIMPLEBUFFER_IS_DBLBUF, 0,
  TAG_END);
  
  s_uwCopRawOffs = simpleBufferGetRawCopperlistInstructionCount(BITPLANES);
  tCopBfr *pCopBfr = s_pView->pCopList->pBackBfr;
  pCopCmds = &pCopBfr->pList[s_uwCopRawOffs];
  
  /*Enable this in double blf mode
  CopyMemQuick(
			s_pView->pCopList->pBackBfr->pList,
			s_pView->pCopList->pFrontBfr->pList,
			s_pView->pCopList->pBackBfr->uwAllocSize
		);*/

  // Since we've set up global CLUT, palette will be loaded from first viewport
  // Colors are 0x0RGB, each channel accepts values from 0 to 15 (0 to F).
  s_pVpMain->pPalette[0] = 0x0000; // First color is also border color
  s_pVpMain->pPalette[1] = 0x0888; // Gray
  s_pVpMain->pPalette[2] = 0x0800; // Red - not max, a bit dark
  s_pVpMain->pPalette[3] = 0x0008; // Blue - same brightness as red

  // We don't need anything from OS anymore
  systemUnuse();

  // Load the view
  viewLoad(s_pView);
}

void ${PROJECTNAME}GsLoop(void) {
  // This will loop forever until you \"pop\" or change gamestate
  // or close the game
  if(keyCheck(KEY_ESCAPE)) {
    gameExit();
    return ;
  }
  vPortWaitForEnd(s_pVpMain);
}

void ${PROJECTNAME}GsDestroy(void) {
  // Cleanup when leaving this gamestate
  systemUse();

  // This will also destroy all associated viewports and viewport managers
  viewDestroy(s_pView);
}" >> ${SRCDIR}/${PROJECTNAME}.c
echo "${SRCDIR}/${PROJECTNAME}.c created"

fi

echo "#ifndef _"$PROJECTNAME"_H_
#define _"$PROJECTNAME"_H_

// Function headers from game.c go here
// It's best to put here only those functions which are needed in other files.

void ${PROJECTNAME}GsCreate(void);

void ${PROJECTNAME}GsLoop(void);

void ${PROJECTNAME}GsDestroy(void);

#endif // _$PROJECTNAME_H_" >> ${SRCDIR}/${PROJECTNAME}.h
echo "${SRCDIR}/${PROJECTNAME}.h created"



echo "
AC_INIT([$PROJECTNAME],[0.1])

AM_INIT_AUTOMAKE([dist-zip silent-rules subdir-objects])

AC_CONFIG_SRCDIR([src/main.c])

AC_PROG_CC([m68k-amigaos-gcc])
#AC_SUBST(CFLAGS,'-m68000 -msoft-float -fomit-frame-pointer -s -noixemul -ffast-math -DAMIGA -DACE_DEBUG=ON -Wall -Wextra -O3')

AC_SUBST(CFLAGS,'-m68000 -msoft-float -fomit-frame-pointer -s -noixemul -ffast-math -DAMIGA -Wall -Wextra -O3')


# Need ace include dir to build the prject
AC_CHECK_HEADERS([stdlib.h ace/managers/key.h ace/managers/game.h ace/utils/chunky.h ace/managers/viewport/simplebuffer.h],[have_ace_includes=yes],[have_ace_includes=no])
if test \"${have_ace_includes}\" = no; then
  AC_MSG_ERROR([Unable to find required ACE include files]);
fi

AC_SEARCH_LIBS([viewCreate], [acerelease],[have_ace_lib=yes],[have_ace_lib=no])
if test \"${have_ace_lib}\" = no; then
  AC_MSG_ERROR([Unable to find required ACE lib file]);
fi

AC_CHECK_PROG([bitmap_conv],[bitmap_conv],[yes],[no],,)
if test \"${bitmap_conv}\" = no; then
  AC_MSG_ERROR([Unable to find bitmap_conv utility, this utility is part of ACE, you can find it under the tool directory]);
fi

AC_CHECK_PROG([palette_conv],[palette_conv],[yes],[no],,)
if test \"${palete_conv}\" = no; then
  AC_MSG_ERROR([Unable to find palette_conv utility, this utility is part of ACE, you can find it under the tool directory]);
fi

AC_CHECK_PROG([assembler],[vasmm68k_mot],[vasmm68k_mot],[no],,)
if test \"${assembler}\" = no; then
  AC_MSG_ERROR([Unable to find vasm68k_mot assembler]);
fi

AC_CHECK_PROG([dd],[dd],[yes],[no],,)
if test \"${dd}\" = no; then
  AC_MSG_ERROR([Unable to find dd utility]);
fi

AC_CONFIG_FILES([Makefile src/Makefile])
# asm=vasmm68k_mot

#AC_DEFINE([ACE_DEBUG], [ON], [Debug on])

AC_OUTPUT

echo \
\"-------------------------------------------------
\${PACKAGE_NAME} Version \${PACKAGE_VERSION}
Compiler: '\${CC} ${CFLAGS} \${CPPFLAGS}'
Bindir: '\${bindir}'
Execprefix: '\${exec_prefix}'
Prefix: '\${prefix}'
--------------------------------------------------\"
" >> ${DIR}/configure.ac
echo "${DIR}configure.ac created"


echo "SUBDIRS = src" >> ${DIR}/Makefile.am
echo "${DIR}Makefile.am created"


echo "bin_PROGRAMS = $PROJECTNAME
${PROJECTNAME}_LDADD = 
${PROJECTNAME}_SOURCES = main.c $PROJECTNAME.c" >> ${SRCDIR}/Makefile.am

echo "File ${SRCDIR}/Makefile.am created"

touch ${DIR}/NEWS ${DIR}/README ${DIR}/AUTHORS ${DIR}/ChangeLog
