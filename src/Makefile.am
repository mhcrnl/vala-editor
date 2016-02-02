bin_PROGRAMS = vala-editor

vala_editor_CPPFLAGS = \
	-DPACKAGE_LOCALE_DIR=\""$(localedir)"\" \
	-DPACKAGE_SRC_DIR=\""$(srcdir)"\" \
	-DPACKAGE_DATA_DIR=\""$(pkgdatadir)"\" \
	$(EDITOR_CFLAGS)
	
vala_editor_CFLAGS = -w
	
icons = icons/class.png \
	icons/codenode.png \
	icons/constant.png \
	icons/constructor.png \
	icons/creationmethod.png \
	icons/delegate.png \
	icons/enum.png \
	icons/enumvalue.png \
	icons/errorcode.png \
	icons/errordomain.png \
	icons/field.png \
	icons/gnome.png \
	icons/interface.png \
	icons/literal.png \
	icons/localvariable.png \
	icons/method.png \
	icons/namespace.png \
	icons/none.png \
	icons/parameter.png \
	icons/property.png \
	icons/signal.png \
	icons/struct.png
	
icons.c:
	echo '<?xml version="1.0" encoding="UTF-8"?>' > resources.xml
	echo '<gresources>' >> resources.xml
	echo '	<gresource prefix="/resources">' >> resources.xml
	$(foreach icon, $(icons), echo '		<file compressed="true">$(icon)</file>' >> resources.xml;)
	echo '	</gresource>' >> resources.xml
	echo '</gresources>' >> resources.xml
	glib-compile-resources resources.xml --sourcedir=$(srcdir) --generate-source --target=$@

vala_editor_VALASOURCES = Document.vala DocumentManager.vala Engine.vala Locator.vala main.vala Provider.vala Window.vala \
	Project.vala Report.vala ReportTable.vala FileSourceView.vala

vala_editor_SOURCES = icons.c $(vala_editor_VALASOURCES:.vala=.c)
	
vala_editor_LDADD = $(EDITOR_LIBS)
vala_editor_VALAFLAGS = --pkg gtksourceview-3.0 --pkg json-glib-1.0 --pkg gee-0.8 \
	--pkg libvala-$(VALA_VERSION) --gresources resources.xml --target-glib=2.38

$(vala_editor_VALASOURCES:.vala=.c): vala.stamp

vala.stamp: $(vala_editor_VALASOURCES)
	valac-$(VALA_VERSION) $(vala_editor_VALAFLAGS) -C $(vala_editor_VALASOURCES)

CLEANFILES = *.c *.o vala-editor *.stamp

DISTCLEANFILES = $(CLEANFILES) *.in *.xml *.ui~
