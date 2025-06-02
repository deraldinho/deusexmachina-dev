# ia_processamento_1/app/main.py
import paho.mqtt.client as mqtt
import os
import time

MQTT_BROKER_HOST = os.getenv("MQTT_BROKER_HOST", "localhost")
MQTT_BROKER_PORT = int(os.getenv("MQTT_BROKER_PORT", 1883))
INPUT_TOPIC = os.getenv("INPUT_TOPIC", "pipeline/default_input")
OUTPUT_TOPIC = os.getenv("OUTPUT_TOPIC", "pipeline/default_output")

def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print(f"IA_Processamento_1: Conectado ao Broker MQTT em {MQTT_BROKER_HOST}:{MQTT_BROKER_PORT}!")
        client.subscribe(INPUT_TOPIC)
        print(f"IA_Processamento_1: Inscrito no tópico '{INPUT_TOPIC}'")
    else:
        print(f"IA_Processamento_1: Falha ao conectar, código de retorno: {rc}")

def on_message(client, userdata, msg):
    payload = msg.payload.decode()
    print(f"IA_Processamento_1: Mensagem recebida no tópico '{msg.topic}': {payload}")
    # Lógica de processamento inicial da IA_1 aqui
    # Por enquanto, apenas reenviando para o próximo tópico
    processed_data = f"IA_1 processou: {payload}"
    client.publish(OUTPUT_TOPIC, processed_data)
    print(f"IA_Processamento_1: Publicado em '{OUTPUT_TOPIC}': {processed_data}")

client = mqtt.Client(client_id="ia_processamento_1_client")
client.on_connect = on_connect
client.on_message = on_message

print("IA_Processamento_1: Tentando conectar ao MQTT...")
try:
    client.connect(MQTT_BROKER_HOST, MQTT_BROKER_PORT, 60)
except Exception as e:
    print(f"IA_Processamento_1: Erro ao conectar ao MQTT: {e}")
    # Adicionar lógica de retry ou sair se preferir
    time.sleep(5) # Espera antes de tentar novamente ou sair
    exit(1) # Ou implemente um loop de retentativa

client.loop_forever() # Mantém o cliente rodando e processando callbacks