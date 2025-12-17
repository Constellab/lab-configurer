FROM mariadb:10.7.4

# Install wget and unzip for database initialization
RUN apt-get update && \
    apt-get install -y wget unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy custom entrypoint script
COPY init-db.sh /usr/local/bin/custom-entrypoint.sh
RUN chmod +x /usr/local/bin/custom-entrypoint.sh

# Use custom entrypoint that handles DB downloads
ENTRYPOINT ["/usr/local/bin/custom-entrypoint.sh"]
CMD ["mysqld"]

# Expose the default MariaDB port
EXPOSE 3306
