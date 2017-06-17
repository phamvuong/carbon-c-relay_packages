# -----------------------------------------------------------------------------
# Makefile for carbon-c-relay
#
# Author: Vuong Pham <vuong.pham@gooddata.com> based on work of Jose Riguera
# Date  : 17-06-2017
#
# -----------------------------------------------------------------------------

CC       = gcc
LINKER   = gcc -o
RM       = rm -f
MD       = mkdir -p
GIT      = git
INSTALL  = install
RPMBUILD = rpmbuild

# project name (generate executable with this name)
DISTDIR          = .
DESTDIR          = /usr/local/etc/carbon
PREFIX           = /usr/local
TARGET           = carbon-c-relay
GIT_VERSION     := $(shell git describe --abbrev=6 --dirty --always || date +%F)
GVCFLAGS        += -DGIT_VERSION=\"$(GIT_VERSION)\" 

# change these to set the proper directories where each files shoould be
SRCDIR   = src
OBJDIR   = obj
BINDIR   = sbin

# compiling flags here
CFLAGS          ?= -O3 -Wall -Werror -Wshadow -pipe
override CFLAGS += $(GVCFLAGS) `pkg-config openssl --cflags` -pthread

# linking flags here
override LIBS   += `pkg-config openssl --libs` -pthread
ifeq ($(shell uname), SunOS)
override LIBS   += -lsocket  -lnsl
endif
LFLAGS           = -O3 -Wall -Werror -Wshadow -pipe -lm $(LIBS)

SOURCES  := $(wildcard $(SRCDIR)/*.c)
INCLUDES := $(wildcard $(SRCDIR)/*.h)
OBJECTS  := $(SOURCES:$(SRCDIR)/%.c=$(OBJDIR)/%.o)

all: folders $(BINDIR)/$(TARGET)

$(BINDIR)/$(TARGET): $(OBJECTS)
	$(LINKER) $@ $(OBJECTS) $(LFLAGS)
	@echo "Linking complete. Binary file created!"

$(OBJECTS): $(OBJDIR)/%.o : $(SRCDIR)/%.c
	$(CC) $(CFLAGS) -c $< -o $@
	@echo "Compiled "$<" successfully!"

.PHONY: folders
folders:
	@$(MD) $(BINDIR) 
	@$(MD) $(OBJDIR)

.PHONY: install
install: $(BINDIR)/$(TARGET)
	$(INSTALL) -m 0755 $< $(PREFIX)/$(BINDIR)/$(TARGET)
	$(INSTALL) -d $(DESTDIR)
	$(INSTALL) -m 0644 config/* $(DESTDIR) 

.PHONY: uninstall
uninstall:
	$(RM) $(PREFIX)/$(BINDIR)/$(TARGET)
	$(RM) -rf $(DESTDIR)/etc/$(TARGET) 


VERSION = $(shell sed -n '/VERSION/s/^.*"\([0-9.]\+\)".*$$/\1/p' $(SRCDIR)/relay.h)
.PHONY: dist
dist:
	@$(GIT) archive \
		--format=tar \
		--prefix=$(TARGET)-$(VERSION)/ HEAD \
		| gzip > $(DISTDIR)/$(TARGET)-$(VERSION).tar.gz
	@echo "Created $(DISTDIR)/$(TARGET)-$(VERSION).tar.gz successfully!"

# Centos/RH packages
.PHONY: rpmbuild
rpmbuild:
	$(RPMBUILD) --define "_topdir ${PWD}/rpm"   -ba rpm/SPECS/$(TARGET).spec

.PHONY: clean
clean:
	@$(RM) $(OBJECTS)
	@$(RM) -r rpm/SOURCES rpm/BUILD rpm/BUILDROOT
	@echo "Cleanup complete!"

.PHONY: dist-clean
distclean: clean
	@$(RM) -r $(BINDIR)
	@$(RM) -r $(OBJDIR)
	@$(RM) -r rpm/SOURCES rpm/BUILD rpm/BUILDROOT rpm/RPMS rpm/SRPMS
	@$(RM) $(TARGET).*$(VERSION).*
	@echo "Executable removed!"
