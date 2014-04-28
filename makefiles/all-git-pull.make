usage:
	@echo "Usage:"
	@echo "  make statues"
	@echo "  make full-statues"
	@echo "  make all-pull"

statues:
	@for d in */ ; do \
		( cd $$d ; echo "###" ; echo "### $$d" ; echo "###" ; git status --short | sed -e 's/^/  /') ; echo "" ; \
	done

full-statues:
	@for d in */ ; do \
		( cd $$d ; echo "###" ; echo "### $$d" ; echo "###" ; git status | sed -e 's/^/  /') ; echo "" ; \
	done

all-pull:
	@for d in */ ; do \
		( cd $$d ; echo "###" ; echo "### $$d" ; echo "###" ; git pull ; ) ; echo "" ; \
	done

