#!/bin/bash
# xtetsuji 2013/11/27
# see: https://github.com/tokuhirom/plenv

set -o errexit

type tempfile >/dev/null 2>&1 || \
function tempfile (){
    echo "plenv-setup-$(date +%s).$$.man"
    return 0
}

if [ "$1" = "-h" ] || [ "$1" = "--help" ] ; then
    if type pod2man >/dev/null 2>&1 ; then
        tempfile=$(tempfile --prefix=plenv-setup --suffix=.man)
        trap "rm -f '$tempfile'" EXIT
        pod2man -u $0 > $tempfile
        man $tempfile
        rm -f -- "$tempfile"
        trap - EXIT
        exit
    else
        sed -ne '/^=pod/,$ p' $0
        exit
    fi
fi

if [ -d ~/.plenv ] ; then
    echo "already exists ~/.plenv. exit."
    exit;
fi

cd
git clone git://github.com/tokuhirom/plenv.git ~/.plenv
echo 'export PATH="$HOME/.plenv/bin:$PATH"' to ~/.bash_profile
echo 'export PATH="$HOME/.plenv/bin:$PATH"' >> ~/.bash_profile

echo 'eval "$(plenv init -)"' to ~/.bash_profile
echo 'eval "$(plenv init -)"' >> ~/.bash_profile

git clone git://github.com/tokuhirom/Perl-Build.git ~/.plenv/plugins/perl-build/

exit

: <<EOF

=pod

=encoding utf-8

=head1 NAME

plenv-setup.sh - plenvセットアップスクリプト

=head2 SYPNOPSIS

 ./plenv-setup.sh

=head2 DESCRIPTION

その後に

 exec $SHELL -l

をしてシェルをリフレッシュ。

build-essentials な環境では

 plenv install 5.18.0

などとしてインストールが開始できる。

詳細は L<https://github.com/tokuhirom/plenv> を参照。

探索パスをリフレッシュするために以下のコマンドを実行。

 plenv rehash

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by OGATA Tetsuji

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

EOF
