listen
======

Listen tcp or udp on shell.

Do you want to listen tcp or udp on shell(bsh, bash, zsh, fish, etc)? Maybe this is what you want!

Status
------

C version: not work

ruby version: tcp: ok, udp: ok, shell wrap: ok

unit test: basic

Build and install
-----------------

    $ make
    $ sudo make install

Usage
-----

    listen [-t [addr:]port] [-u [addr:]port] command
        -t   listen to tcp
        -u   listen to udp
        You can listen multi port(both tcp & udp) at once

Once a tcp linked in, command will be executed, and all steam will pass to stdin, all stdout will send back to client.

Once an udp received, command will be executed, and all data will pass to std, all stdout will send back to client.

For example:

    $ listen -t 1234 sed -u 's/[aeiou]//g'

    # in another terminal
    $ telnet 127.0.0.1 1234
    hello world!
    hll wrld!

**NOTICE**

Some shell commands have buffering, If you use commands in this way, have a look here: https://www.perkin.org.uk/posts/how-to-fix-stdio-buffering.html
