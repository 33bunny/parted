#
# You must set the $(lang) variable when you include this makefile.
#
# You can use the $(po4a_translate_options) variable to specify additional
# options to po4a.
# For example: po4a_translate_options=-L KOI8-R -A KOI8-R
#
#
# This makefile deals with the manpages generated from POs with po4a, and
# should be included in an automake Makefile.am.
#
# The po must be named:
#   <man>.$(lang).po
# If a man page require an addendum, you must name it:
#   <man>.$(lang).po.addendum
# Where <man> corresponds to a filename in the C directory (which contains
# the English man pages).
#
# The POs suffix is $(lang).po to allow dl10n to detect the outdated POs.
#
#
# If a man page cannot be generated (it is not sufficiently translated; the
# threshold is 80%), it won't be distributed, and the build won't fail.
#

mandir = @mandir@/$(lang)

# Inform automake that we want to install some man pages in section 1, 5
# and 8.
# We can't simply use:
# dist_man_MANS = $(wildcard *.[1-9])
# Because when Makefile.in is generated, dist_man_MANS is empty, and
# automake do not generate the install-man targets.
dist_man_MANS = fake-page.1 fake-page.5 fake-page.8

# Do not fail if these man pages do not exist
.PHONY: fake-page.1 fake-page.5 fake-page.8

# Override the automake's install-man target.
# And set dist_man_MANS according to the pages that could be generated
# when this target is called.
install-man: dist_man_MANS = $(wildcard *.[1-9])
install-man: install-man1 install-man5 install-man8

# For each .po, try to generate the man page
all-local:
	for po in $(srcdir)/*.$(lang).po; do \
		$(MAKE) $$(basename $${po%.$(lang).po}); \
	done

# Remove the man pages that were generated from a .po
clean-local:
	for po in $(srcdir)/*.$(lang).po; do \
		rm -f $$(basename $${po%.$(lang).po}); \
	done

.PHONY: updatepo
# Update the PO in srcdir, according to the POT in C.
# Based on the gettext po/Makefile.in.in
updatepo:
	tmpdir=`pwd`; \
	cd $(srcdir); \
	for po in *.$(lang).po; do \
	  pot=../C/po/$${po%$(lang).po}pot; \
	  echo "$(MSGMERGE) $$po $$pot -o $${po%po}new.po"; \
	  if $(MSGMERGE) $$po $$pot -o $$tmpdir/$${po%po}new.po; then \
	    if cmp $$po $$tmpdir/$${po%po}new.po >/dev/null 2>&1; then \
	      rm -f $$tmpdir/$${po%po}new.po; \
	    else \
	      if mv -f $$tmpdir/$${po%po}new.po $$po; then \
	        :; \
	      else \
	        echo "msgmerge for $$po failed: cannot move $$tmpdir/$${po%po}new.po to $$po" 1>&2; \
	        exit 1; \
	      fi; \
	    fi; \
	  else \
	    echo "msgmerge for $$po failed!" 1>&2; \
	    rm -f $$tmpdir/$${po%po}new.po; \
	  fi; \
	  msgfmt -o /dev/null --statistics $$po; \
	done

dist-hook: updatepo

# Build the pages with an addendum
%: $(srcdir)/%.$(lang).po $(srcdir)/../C/% $(srcdir)/%.$(lang).po.addendum
	po4a-translate -f man -m $(srcdir)/../C/$@ -p $< -l $@ -a $(srcdir)/$@.$(lang).po.addendum $(po4a_translate_options)

# Build the pages without addendum
%: $(srcdir)/%.$(lang).po $(srcdir)/../C/%
	po4a-translate -f man -m $(srcdir)/../C/$@ -p $< -l $@ $(po4a_translate_options)

