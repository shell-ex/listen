listen
======

Listen tcp or udp on shell.

Do you want to listen tcp or udp on shell(bsh, bash, zsh, fish, etc)? Maybe this is what you want!

Build and install
-----------------

    $ make
    $ sudo make install

Usage
-----

    $ listen [-t [addr]:port] [-u [addr]:port] command

Once a tcp linked in, command will be executed, and all steam will pass to stdin, all stdout will send back to client.

Once an udp received, command will be executed, and all data will pass to std, all stdout will send back to client.

For example:

    $ listen -t 1234 tac

    # in another terminal
    $ telnet 127.0.0.1 1234
    hello world!
    !dlrow olleh
    ^D


