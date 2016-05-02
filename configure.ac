AC_PREREQ([2.65])
AC_INIT([vala-editor], [0.1], [inizan.yannick@gmail.com], [vala-editor])
AC_CONFIG_MACRO_DIR([m4])
AM_INIT_AUTOMAKE
AC_CONFIG_FILES([Makefile
	vala-editor.edi
	src/Makefile])

AM_PROG_AR
LT_INIT
AC_PROG_CC
AM_PROG_VALAC

VALA_VERSION=0.30

AC_ARG_WITH(
    vala,
    AS_HELP_STRING(
	[--with-vala=VERSION],
	[specify vala version]
    ),
    [
	VALA_VERSION="$withval"
    ],
    [VALA_VERSION=0.30]
)

AC_SUBST(VALA_VERSION)

PKG_CHECK_MODULES(EDITOR, [gtksourceview-3.0 json-glib-1.0 gee-0.8 libvala-$VALA_VERSION])
AC_SUBST(EDITOR_CFLAGS)
AC_SUBST(EDITOR_LIBS)

AC_OUTPUT
