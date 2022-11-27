FROM alpine:3.17

# Install OpenSSH server and Gitolite
# Unlock the automatically-created git user
RUN set -x \
    && addgroup -S -g 1000 git \
    && adduser -S -D -H -h /var/lib/git -s /bin/sh -u 1000 -G git -g git git \
    && sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories \
    && apk add --no-cache gitolite openssh \
    && passwd -u git

# Volume used to store SSH host keys, generated on first run
VOLUME /etc/ssh/keys

# Volume used to store all Gitolite data (keys, config and repositories), initialized on first run
VOLUME /var/lib/git

COPY sshd_config /etc/ssh/sshd_config

# Entrypoint responsible for SSH host keys generation, and Gitolite data initialization
COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]

# Expose port 22 to access SSH
EXPOSE 22

# Default command is to run the SSH server
CMD ["/usr/sbin/sshd", "-D"]
