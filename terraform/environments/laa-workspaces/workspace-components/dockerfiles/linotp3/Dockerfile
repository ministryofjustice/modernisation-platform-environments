FROM linotp/linotp:3.4.4

USER root

COPY entrypoint.sh /usr/local/bin/custom-entrypoint.sh
RUN chmod +x /usr/local/bin/custom-entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/custom-entrypoint.sh"]
