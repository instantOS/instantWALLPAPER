export PREFIX := /usr/

.PHONY: all
all:
	$(info Usage: make install [PREFIX=/usr/])
	true

.PHONY: install
install: wall.sh wallutils.sh
	$(info "INFO: install PREFIX: $(PREFIX)")
	mkdir -p $(DESTDIR)$(PREFIX)share/instantwallpaper
	install -Dm 755 wall.sh $(DESTDIR)$(PREFIX)bin/instantwallpaper
	install -m 644 wallutils.sh $(DESTDIR)$(PREFIX)share/instantwallpaper/

.PHONY: uninstall
uninstall:
	rm -r $(DESTDIR)$(PREFIX)share/instantwallpaper
	rm -f $(DESTDIR)$(PREFIX)bin/instantwallpaper
