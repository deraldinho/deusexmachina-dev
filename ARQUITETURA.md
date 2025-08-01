# Documentação da Arquitetura e Fluxo de Trabalho do Projeto DeuxExMachina

## 1. Visão Geral do Projeto

O DeuxExMachina visa ser uma plataforma de inteligência artificial modular e "All-in-One", gerenciável por múltiplos "brains" (cores de IA) especializados que colaboram para processar informações, automatizar tarefas e fornecer respostas consolidadas e precisas. A inspiração conceitual é um sistema inteligente e integrado como o J.A.R.V.I.S.

## 2. Ambiente de Infraestrutura

* **Máquina Virtual (VM):** Gerenciada por Vagrant, provisionada com **CentOS Stream 10**.
    * Configurada com scripts shell para instalar todas as dependências necessárias: Docker, Docker Compose, Python, Node.js, ferramentas de monitoramento (Netdata, htop, Glances), ferramentas de segurança (Firewalld), e outras essenciais.
    * Configuração de timezone e locale para o Brasil.
* **Workspace de Desenvolvimento:**
    * O diretório `/home/vagrant` na VM é compartilhado via Samba. Dentro dele, a subpasta `/home/vagrant/projetos` é o local designado para os projetos.
    * Este diretório **não é sincronizado** com o computador host via `synced_folder` do Vagrant, garantindo um ambiente de desenvolvimento contido na VM.
    * O acesso a este workspace a partir do computador host é feito via **Samba**. A senha para o usuário `vagrant` pode ser pré-configurada através da variável `SAMBA_PASSWORD` no arquivo `.env` do host.
* **Containerização:** Todos os componentes da IA (os "brains"), bancos de dados e serviços de mensageria (MQTT) rodarão como contêineres Docker, orquestrados por um arquivo `docker-compose.yml` localizado no workspace de desenvolvimento (`/home/vagrant/projetos`).

## 3. Arquitetura dos "Brains" de IA

O sistema é composto por "brains" (cores de IA) especializados, cada um com uma responsabilidade definida.

### Componentes Principais:

1.  **`brain_input_processor` (Cérebro de Entrada):**
    * **Função:** Ponto de entrada único para todas as requisições e inputs externos (ex: prompts de usuário, chamadas de API, dados de sensores, upload de arquivos).
    * **Responsabilidades:**
        * Receber e validar o input.
        * Realizar um pré-processamento (limpeza, normalização, identificação básica do tipo de input/intenção).
        * Atuar como um "pré-raciocínio", decidindo para qual(is) "brain(s)" de processamento a tarefa deve ser encaminhada.
        * Opcionalmente, registrar a requisição inicial através do `storage_brain`.
        * Publicar a tarefa pré-processada em um tópico MQTT apropriado.
    * **Tecnologia Sugerida:** Python com Flask/FastAPI (para expor uma API HTTP) e Paho-MQTT (para comunicação).

2.  **`processing_brain_1` e `processing_brain_2` (Cérebros de Processamento):**
    * **Função:** Cores de IA especializados em diferentes tipos de tarefas de processamento e refinamento da informação.
    * **Responsabilidades:**
        * Inscrever-se em tópicos MQTT específicos para receber tarefas do `brain_input_processor` ou de outros "brains" de processamento.
        * Executar a lógica de IA específica para sua especialidade (ex: processamento de linguagem natural, análise de dados, visão computacional, etc.).
        * Interagir com o `storage_brain` (via MQTT ou API interna) para:
            * Consultar dados contextuais, conhecimento prévio ou informações de suporte.
            * Salvar resultados intermediários ou novos conhecimentos adquiridos.
        * Publicar seus resultados processados/refinados em tópicos MQTT para o próximo estágio (outro `processing_brain` ou o `output_brain`).
    * **Tecnologia Sugerida:** Python (devido ao vasto ecossistema de IA/ML) ou Node.js para tarefas I/O-bound, conforme a necessidade específica do core.

3.  **`storage_brain` (Cérebro de Armazenamento):**
    * **Função:** ÚNICO componente com acesso direto e responsabilidade de gerenciar a persistência de dados do sistema.
    * **Responsabilidades:**
        * Interagir com o(s) banco(s) de dados (ex: PostgreSQL, MongoDB, Redis, etc., rodando como contêineres Docker).
        * Receber requisições de outros "brains" (via MQTT ou API interna dedicada) para operações CRUD (Criar, Ler, Atualizar, Deletar) dados.
        * Abstrair a lógica de acesso ao banco de dados, o esquema e as otimizações de consulta.
        * Garantir a integridade e consistência dos dados.
        * Publicar respostas de consultas ou status de operações de escrita em tópicos MQTT de resposta.
    * **Tecnologia Sugerida:** Python ou Node.js, com as bibliotecas de cliente apropriadas para o(s) banco(s) de dados escolhido(s).

4.  **`output_brain` (Cérebro de Saída):**
    * **Função:** Responsável por coletar, formatar e entregar a informação final processada ao usuário ou sistema de destino.
    * **Responsabilidades:**
        * Inscrever-se em tópicos MQTT que contêm os resultados finais ou consolidados dos "brains" de processamento.
        * Opcionalmente, consultar o `storage_brain` para obter informações adicionais para formatação ou enriquecimento da saída.
        * Formatar os dados para o formato de saída desejado (texto, JSON, resposta de API, comando para dispositivo, etc.).
        * Entregar o output (ex: responder a uma chamada de API, enviar uma notificação, exibir em uma interface, acionar um dispositivo IoT).
    * **Tecnologia Sugerida:** Python ou Node.js.

### Componentes de Suporte:

* **Broker MQTT (ex: Mosquitto):**
    * Rodando como um contêiner Docker.
    * Serve como o sistema nervoso central para a comunicação assíncrona entre todos os "brains".
* **Banco(s) de Dados (ex: PostgreSQL, MongoDB):**
    * Rodando como contêiner(es) Docker.
    * Acessado exclusivamente pelo `storage_brain`.

## 4. Fluxo de Trabalho e Comunicação (Organograma)

O fluxo de informação geralmente seguirá o padrão:

```mermaid
graph TD
    A[Input Externo] --> B(brain_input_processor);

    subgraph "DeuxExMachina - Serviços na VM"
        direction LR
        B -->|Tarefa Pré-Processada<br>(MQTT)| C{MQTT Broker};
        
        C -->|Tarefa| D(processing_brain_1);
        C -->|Tarefa| E(processing_brain_2);
        
        B ---->|Log de Input (Opcional)<br>(MQTT)| F(storage_brain);

        D <-->|Dados<br>(MQTT)| F;
        E <-->|Dados<br>(MQTT)| F;
        
        F <-->|CRUD| G[Banco de Dados];

        D -->|Resultado Parcial/Final<br>(MQTT)| C;
        E -->|Resultado Parcial/Final<br>(MQTT)| C;
        
        C -->|Resultado(s) para Saída| H(output_brain);
        H <-->|Dados para Formatação<br>(MQTT)| F;
    end

    H -->|Output Formatado| I[Usuário / Sistema Externo];