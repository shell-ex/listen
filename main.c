#include <stdio.h>
#include <sys/select.h>
#include <netinet/in.h>
#include <errno.h>
#include <string.h>

fd_set g_listen_fds;
fd_set g_read_fds;
int g_max_fd = -1;

void init() {
	FD_ZERO(&g_listen_fds);
	FD_ZERO(&g_read_fds);
}

int listen_tcp(char * addr_str, int port) {
	struct sockaddr_in addr;
	int fd;

	fd = socket(AF_INET, SOCK_STREAM, 0);
	if (fd < 0) {
		return errno;
	}

	addr.sin_family = AF_INET;
	if (addr_str) {
		if (!inet_aton(addr_str, addr.sin_addr)) {
			return EADDRNOTAVAIL;
		}
	} else {
		addr.sin_addr.s_addr = INADDR_ANY;
	}
	addr.sin_port = htons(port);
	memset(&(addr.sin_zero), '\0', 8);

	if (bind(fd, (struct sockaddr *)&addr, sizeof(addr)) == -1) {
		return errno;
	}

	listen(fd, 64);

	FD_SET(fd, &g_listen_fds);
	FD_SET(fd, &g_read_fds);

	if (fd > g_max_fd)
		g_max_fd = fd;

	return fd;
}

void on_new_link(int fd) {
	int newfd;
	struct sockaddr_in clientaddr;
	int addrlen;

	addrlen = sizeof(clientaddr);

	newfd = accept(fd, (struct sockaddr *)&clientaddr, &addrlen);
	if (newfd == -1) {
		perror("accept error!");
		return;
	}

	FD_SET(newfd, &g_read_fds);
	if (newfd > g_max_fd)
		g_max_fd = newfd;
}

void on_data_arrive(int fd, const char * buf, int nbuf) {
	// just send back
	send(fd, buf, nbuf, 0);
}

void on_fd_valid(fd) {
	int nbytes;
	char buf[4096];
	
	nbytes = recv(fd, buf, 4096, MSG_DONTWAIT);
	if (nbytes > 0) {
		on_data_arrive(fd, buf, nbytes);
	} else if (nbytes == 0) {
		close(fd);
		FD_CLR(fd, &g_read_fds);
	} else {
		// no data or error
		return;
	}
}

int run_loop() {
	for (;;) {
		int i;
		int n;
		fd_set read_fds;
		int fdmax;

		read_fds = g_read_fds;
		fdmax = g_max_fd;

		n = select(fdmax + 1, &read_fds, NULL, NULL, NULL);
		if (n == -1) {
			return errno;
		}

		for (i = 0; i < fdmax + 1; ++i) {
			if (FD_ISSET(i, &read_fds)) {
				if (FD_ISSET(i, &g_listen_fds)) {
					on_new_link(i);
				} else {
					on_fd_valid(i);
				}
			}
		}
	}
}

int main(int argc, char * argv[]) {
	init();
	listen_tcp(NULL, 8123);
	return run_loop();
}
