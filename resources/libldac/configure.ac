AC_INIT([libldac], [2.0.2])
AM_INIT_AUTOMAKE([foreign subdir-objects -Wall -Werror])

AC_PROG_CC
AM_PROG_AR
AM_PROG_CC_C_O
LT_INIT


AC_DEFUN([AX_APPEND_FLAG],
[dnl
AC_PREREQ(2.64)dnl for _AC_LANG_PREFIX and AS_VAR_SET_IF
AS_VAR_PUSHDEF([FLAGS], [m4_default($2,_AC_LANG_PREFIX[FLAGS])])
AS_VAR_SET_IF(FLAGS,[
  AS_CASE([" AS_VAR_GET(FLAGS) "],
    [*" $1 "*], [AC_RUN_LOG([: FLAGS already contains $1])],
    [
     AS_VAR_APPEND(FLAGS,[" $1"])
     AC_RUN_LOG([: FLAGS="$FLAGS"])
    ])
  ],
  [
  AS_VAR_SET(FLAGS,[$1])
  AC_RUN_LOG([: FLAGS="$FLAGS"])
  ])
AS_VAR_POPDEF([FLAGS])dnl
])dnl AX_APPEND_FLAG

AC_ARG_ENABLE([debug],
	AS_HELP_STRING([--enable-debug], [enable debugging support]))
AM_CONDITIONAL([ENABLE_DEBUG], [test "x$enable_debug" = "xyes"])
AM_COND_IF([ENABLE_DEBUG], [
	AX_APPEND_FLAG([-DLOCAL_DEBUG])
])

AC_CONFIG_FILES([
	Makefile
	libldacBT.pc
	libldacBT_abr.pc])
AC_OUTPUT
