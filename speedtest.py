import speedtest
import mysql.connector
from datetime import datetime
import time
import sys

# ========================
# CONFIG
# ========================
DB_CONFIG = {
    "host": "192.168.1.110",
    "user": "speedtest",
    "password": "SD#$gfgfy$%$53ddsfh6",
    "database": "speedtest",
    "connection_timeout": 10
}

MAX_RETRY = 3
RETRY_DELAY = 10  # segundos


# ========================
# LOG
# ========================
def log(msg):
    print(f"[{datetime.now()}] {msg}")
    sys.stdout.flush()


# ========================
# BANCO
# ========================
def conectar_banco():
    return mysql.connector.connect(**DB_CONFIG)


# ========================
# TESTE DE VELOCIDADE
# ========================
def testar_velocidade():
    log("Iniciando teste de velocidade...")

    st = speedtest.Speedtest(timeout=30)

    # evita travamentos iniciais
    st.get_servers([])
    best = st.get_best_server()

    log(f"Servidor escolhido: {best['sponsor']} ({best['host']})")

    download = st.download() / 1e6
    upload = st.upload() / 1e6
    ping = st.results.ping

    ip = st.results.client['ip']
    isp = best['host']
    servidor = best['sponsor']

    log(f"Download: {download:.2f} Mbps")
    log(f"Upload: {upload:.2f} Mbps")
    log(f"Ping: {ping} ms")

    return {
        "data": datetime.now(),
        "download": download,
        "upload": upload,
        "ping": ping,
        "isp": isp,
        "servidor": servidor,
        "ip": ip
    }


# ========================
# SALVAR NO BANCO
# ========================
def salvar(resultado):
    conn = conectar_banco()
    cursor = conn.cursor()

    sql = """
    INSERT INTO resultados 
    (data_teste, download, upload, ping, isp, servidor_proximo, endereco_ip)
    VALUES (%s, %s, %s, %s, %s, %s, %s)
    """

    valores = (
        resultado["data"],
        resultado["download"],
        resultado["upload"],
        resultado["ping"],
        resultado["isp"],
        resultado["servidor"],
        resultado["ip"]
    )

    cursor.execute(sql, valores)
    conn.commit()
    conn.close()

    log("Resultado salvo no banco.")


# ========================
# EXECUÇÃO COM RETRY
# ========================
def executar():
    for tentativa in range(1, MAX_RETRY + 1):
        try:
            log(f"Tentativa {tentativa}...")
            resultado = testar_velocidade()
            salvar(resultado)
            log("Teste finalizado com sucesso.")
            return

        except Exception as e:
            log(f"Erro: {e}")

            if tentativa < MAX_RETRY:
                log(f"Tentando novamente em {RETRY_DELAY}s...")
                time.sleep(RETRY_DELAY)
            else:
                log("Falha após várias tentativas.")


# ========================
# MAIN
# ========================
if __name__ == "__main__":
    executar()
