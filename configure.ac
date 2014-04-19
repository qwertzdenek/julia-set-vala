AC_PREREQ(2.60)
AC_INIT([julius], [1.0], [janecekz@students.zcu.cz])
AM_INIT_AUTOMAKE([-Wall subdir-objects foreign])
AM_SILENT_RULES(yes)

# check for source files
AC_CONFIG_SRCDIR([src/App.vala])

# check for the C compiler
AC_PROG_CC

AM_PROG_VALAC
#PKG_CONFIG="pkg-config --static"
PKG_CHECK_MODULES(DEPS, [glib-2.0 gtk+-3.0 gdk-pixbuf-2.0])
AC_CHECK_LIB([m], [sqrt])

AC_CONFIG_FILES([Makefile])
AC_OUTPUT

