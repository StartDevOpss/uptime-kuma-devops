# ─────────────────────────────────────────
# Imagem base oficial do Uptime Kuma
# Usamos a imagem oficial para garantir
# que tudo já está configurado corretamente
# ─────────────────────────────────────────
FROM louislam/uptime-kuma:1

# Porta que a aplicação usa internamente
EXPOSE 3001

# Diretório onde o Uptime Kuma salva os dados
# (banco de dados SQLite, configs, etc.)
VOLUME ["/app/data"]

# Comando padrão de inicialização
CMD ["node", "server/server.js"]
