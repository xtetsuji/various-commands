usage:
	@echo "Usage:"
	@echo "  make statues"
	@echo "  make full-statues"
	@echo "  make all-pull"

statues:
	@for d in */ ; do \
		( cd $$d ; echo "###" ; echo "### $$d" ; echo "###" ; git status --short | sed -e 's/^/  /') ; \
	done

full-statues:
	@for d in */ ; do \
		( cd $$d ; echo "###" ; echo "### $$d" ; echo "###" ; git status | sed -e 's/^/  /') ; \
	done

all-pull:
	@for d in */ ; do \
		( cd $$d ; echo "###" ; echo "### $$d" ; echo "###" ; git pull ; ) ; \
	done

