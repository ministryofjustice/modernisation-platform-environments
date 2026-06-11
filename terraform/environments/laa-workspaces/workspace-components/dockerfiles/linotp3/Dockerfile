FROM linotp/linotp:3

COPY linotp-http.conf /etc/apache2/sites-available/linotp-http.conf
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh \
    && a2ensite linotp-http \
    && a2dissite 000-default default-ssl linotp 2>/dev/null || true \
    && a2enmod wsgi headers

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
