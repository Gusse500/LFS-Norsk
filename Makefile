# vim:ts=3
RENDERTMP = $(HOME)/tmp
CHUNK_QUIET = 1
ROOT_ID =
SHELL = /bin/bash

ifdef V
  Q =
else
  Q = @
endif

ifndef REV
  REV = systemd
endif

ifneq ($(REV), sysv)
  ifneq ($(REV), systemd)
    $(feil REV må være 'sysv' eller 'systemd' (standard).)
  endif
endif

ifeq ($(REV), sysv)
  BASEDIR         ?= $(HOME)/public_html/lfs-book
  PDF_OUTPUT      ?= LFS-BOOK.pdf
  NOCHUNKS_OUTPUT ?= LFS-BOOK.html
  DUMPDIR         ?= $(HOME)/lfs-commands
else
  BASEDIR         ?= $(HOME)/public_html/lfs-systemd
  PDF_OUTPUT      ?= LFS-SYSD-BOOK.pdf
  NOCHUNKS_OUTPUT ?= LFS-SYSD-BOOK.html
  DUMPDIR         ?= $(HOME)/lfs-sysd-commands
endif

book: validate profile-html
	@echo "Genererer delte XHTML filer på $(BASEDIR)/ ..."
	$(Q)xsltproc --nonet                          \
      --stringparam chunk.quietly $(CHUNK_QUIET) \
      --stringparam rootid "$(ROOT_ID)"          \
      --stringparam base.dir $(BASEDIR)/         \
      stylesheets/lfs-chunked.xsl                \
      $(RENDERTMP)/lfs-html.xml

	@echo "Kopierer av CSS kode og bilder..."
	$(Q)mkdir -p $(BASEDIR)/stylesheets
	$(Q)cp stylesheets/lfs-xsl/*.css $(BASEDIR)/stylesheets
	$(Q)sed -e 's|../stylesheet|stylesheet|' \
           -i $(BASEDIR)/index.html

	$(Q)mkdir -p $(BASEDIR)/images
	$(Q)cp images/*.png $(BASEDIR)/images

	@echo "Kjører Tidy og obfuscate.sh..."
	$(Q)for filename in `find $(BASEDIR) -name "*.html"`; do \
         tidy -config tidy.conf $$filename;           \
         /bin/bash obfuscate.sh $$filename;           \
         sed -e "s|text/html|application/xhtml+xml|g" \
             -i $$filename;                           \
       done

	$(Q)$(MAKE) --no-print-directory wget-list md5sums

pdf: validate
	@echo "Genererer profilert XML for PDF..."
	$(Q)xsltproc --nonet \
                --stringparam profile.condition pdf \
                --output $(RENDERTMP)/lfs-pdf.xml   \
                stylesheets/lfs-xsl/profile.xsl     \
                $(RENDERTMP)/lfs-full.xml

	@echo "Genererer FO fil..."
	$(Q)xsltproc --nonet                           \
                 --stringparam rootid "$(ROOT_ID)" \
                 --output $(RENDERTMP)/lfs-pdf.fo  \
                 stylesheets/lfs-pdf.xsl           \
                 $(RENDERTMP)/lfs-pdf.xml

	$(Q)sed -i -e 's/span="inherit"/span="all"/' $(RENDERTMP)/lfs-pdf.fo
	$(Q)bash pdf-fixups.sh $(RENDERTMP)/lfs-pdf.fo

	@echo "Genererer PDF fil..."
	$(Q)mkdir -p $(RENDERTMP)/images
	$(Q)cp images/*.png $(RENDERTMP)/images

	$(Q)mkdir -p $(BASEDIR)

	$(Q)fop -q  $(RENDERTMP)/lfs-pdf.fo $(BASEDIR)/$(PDF_OUTPUT) 2>fop.log
	@echo "$(BASEDIR)/$(PDF_OUTPUT) opprettet"
	@echo "fop.log opprettet"

nochunks: validate profile-html
	@echo "Genererer ikke-delt XHTML fil..."
	$(Q)xsltproc --nonet                                \
                --stringparam rootid "$(ROOT_ID)"      \
                --output $(BASEDIR)/$(NOCHUNKS_OUTPUT) \
                stylesheets/lfs-nochunks.xsl           \
                $(RENDERTMP)/lfs-html.xml

	@echo "Kjører Tidy..."
	$(Q)tidy -config tidy.conf $(BASEDIR)/$(NOCHUNKS_OUTPUT) || test $$? -le 1

	@echo "Kjører obfuscate.sh..."
	$(Q)bash obfuscate.sh      $(BASEDIR)/$(NOCHUNKS_OUTPUT)
	$(Q)sed -e "s|text/html|application/xhtml+xml|g" \
           -e "s|../wget-list|wget-list|"           \
           -e "s|../md5sums|md5sums|"               \
           -i $(BASEDIR)/$(NOCHUNKS_OUTPUT)

	@echo "Utdata ved $(BASEDIR)/$(NOCHUNKS_OUTPUT)"

tmpdir:
	@echo "Oppretting og rengjøring $(RENDERTMP)"
	$(Q)mkdir -p $(RENDERTMP)
	$(Q)rm -f $(RENDERTMP)/lfs*.xml
	$(Q)rm -f $(RENDERTMP)/*wget*
	$(Q)rm -f $(RENDERTMP)/*md5sum*
	$(Q)rm -f $(RENDERTMP)/*pdf.fo

validate: tmpdir version
	@echo "Behandler oppstartsskripter..."
	$(Q)bash process-scripts.sh

	@echo "Justerer for revisjon $(REV)..."
	$(Q)xsltproc --nonet                               \
                --xinclude                            \
                --stringparam profile.revision $(REV) \
                --output $(RENDERTMP)/lfs-html2.xml   \
                stylesheets/lfs-xsl/profile.xsl       \
                index.xml

	@echo "Validerer boken..."
	$(Q)xmllint --nonet                            \
               --encode UTF-8                     \
               --postvalid --valid                \
               --output $(RENDERTMP)/lfs-full.xml \
               $(RENDERTMP)/lfs-html2.xml

	$(Q)rm -f appendices/*.script
	$(Q)./aux-file-data.sh $(RENDERTMP)/lfs-full.xml
	@echo "Validering fullført."

profile-html: validate
	@echo "Genererer profilert XML for XHTML..."
	$(Q)xsltproc --nonet                              \
                --stringparam profile.condition html \
                --output $(RENDERTMP)/lfs-html.xml   \
                stylesheets/lfs-xsl/profile.xsl      \
                $(RENDERTMP)/lfs-full.xml

DOWNLOADS_DEP = chapter03/packages.xml chapter03/patches.xml \
                packages.ent patches.ent general.ent

wget-list: $(BASEDIR)/wget-list $(BASEDIR)/wget-list-$(REV)
$(BASEDIR)/wget-list: stylesheets/wget-list.xsl $(DOWNLOADS_DEP)
	@echo "Genererer konsolidert wget liste på $(BASEDIR)/wget-list ..."
	$(Q)mkdir -p $(BASEDIR)
	$(Q)xsltproc --nonet                       \
                --xinclude                    \
                --output $(BASEDIR)/wget-list \
                stylesheets/wget-list.xsl     \
                chapter03/chapter03.xml

$(BASEDIR)/wget-list-$(REV): stylesheets/wget-list.xsl $(DOWNLOADS_DEP)
	$(Q)xsltproc --nonet                               \
                --xinclude                            \
                --stringparam profile.revision $(REV) \
                --output $(RENDERTMP)/wget-list.xml   \
                stylesheets/lfs-xsl/profile.xsl       \
                chapter03/chapter03.xml

	$(Q)xsltproc --nonet                              \
                --output $(BASEDIR)/wget-list-$(REV) \
                stylesheets/wget-list.xsl            \
                $(RENDERTMP)/wget-list.xml

md5sums: $(BASEDIR)/md5sums
$(BASEDIR)/md5sums: stylesheets/wget-list.xsl $(DOWNLOADS_DEP)
	@echo "Genererer konsolidert md5sum fil på $(BASEDIR)/md5sums ..."
	$(Q)mkdir -p $(BASEDIR)

	$(Q)xsltproc --nonet                               \
                --xinclude                            \
                --stringparam profile.revision $(REV) \
                --output $(RENDERTMP)/md5sum.xml      \
                stylesheets/lfs-xsl/profile.xsl       \
                chapter03/chapter03.xml

	$(Q)xsltproc --nonet                     \
                --output $(BASEDIR)/md5sums \
                stylesheets/md5sum.xsl      \
                $(RENDERTMP)/md5sum.xml
	$(Q)sed -i -e \
       "s/BOOTSCRIPTS-MD5SUM/$(shell md5sum lfs-bootscripts*.tar.xz | cut -d' ' -f1)/" \
       $(BASEDIR)/md5sums

version:
	$(Q)./git-version.sh $(REV)

dump-commands: validate
	@echo "Dumping av bokkommandoer..."

	$(Q)rm -rf $(DUMPDIR)

	$(Q)xsltproc --output $(DUMPDIR)/          \
                stylesheets/dump-commands.xsl \
                $(RENDERTMP)/lfs-full.xml
	@echo "Dumping av bokkommandoer fullført om $(DUMPDIR)"

all: book nochunks pdf dump-commands

dist:
	$(Q)DIST=/tmp/LFS-RELEASE ./git-version.sh $(REV)
	$(Q)rm -f lfs-$$(</tmp/LFS-RELEASE).tar.xz
	$(Q)tar cJf lfs-$$(</tmp/LFS-RELEASE).tar.xz \
		$(shell git ls-tree HEAD . --name-only -r) version.ent \
		-C /tmp LFS-RELEASE \
		--transform "s,^,lfs-$$(</tmp/LFS-RELEASE)/,"
	$(Q)echo "Genererer XML tarball lfs-$$(</tmp/LFS-RELEASE).tar.xz"

.PHONY : all book dump-commands nochunks pdf profile-html tmpdir validate md5sums wget-list version dist

