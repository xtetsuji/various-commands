# Initial commit at 2014/05/17
# rep2の管理ファイルだと思うけど、
# 太古のファイルなので何をしているのかよくわかっていない

usage:
	@echo "Usage:"
	@echo "  make setup"

setup:
	@if [ ! -d data ] ; then \
		echo "create data directory" ; \
		mkdir data ; \
		chmod 707 data ; \
	fi
	@if [ ! -d cache ] ; then \
		echo "create cache directory for ImageCache2" ; \
		mkdir cache ; \
		chmod 707 cache ; \
	fi
	@if [ ! -d includes ] ; then \
		echo "p2pear includes directory is not exists." ; \
	fi
	@echo "Attach conf_user.inc.php and conf_user_style.inc.php"

# 1. p2 を Apache の指定ディレクトリに展開する
# 2. p2pear/includes/ を、上記指定ディレクトリに置く
# 2. そのディレクトリにこの Makefile を置く
# 3. sudo -u www-data make setup (sudo は適宜)
