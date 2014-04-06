AM_LDFLAGS = -lm `pkg-config --libs glib-2.0 gtk+-3.0 clutter-gtk-1.0`
AM_CFLAGS = `pkg-config --cflags glib-2.0 gtk+-3.0 clutter-gtk-1.0`

bin_PROGRAMS = app
app_SOURCES = App.vala Julius.vala Presets.vala
app_VALAFLAGS = --pkg gtk+-3.0 --pkg clutter-gtk-1.0

