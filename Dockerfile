FROM mlikiowa/napcat-docker:latest

# Rename original entrypoint
RUN mv /app/entrypoint.sh /app/entrypoint-original.sh 2>/dev/null || true

# Copy our custom entrypoint
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

EXPOSE 6099 3001

ENTRYPOINT ["bash", "/app/entrypoint.sh"]