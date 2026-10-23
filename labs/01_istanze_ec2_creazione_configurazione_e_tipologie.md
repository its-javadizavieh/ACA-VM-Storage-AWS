# Lab 01 - Istanze EC2: Creazione, Configurazione e Tipologie

## Obiettivo

- Focus operativo: avviare un'istanza EC2 coerente con uno scenario a basso traffico e budget limitato, scegliendo tipo, AMI, key pair e Security Group corretti, poi verificarne la raggiungibilità in SSH.
- Deliverable atteso: istanza `running` (poi fermata/terminata) con tipo, AMI ID e Security Group documentati, evidenza SSH riuscita, nota di motivazione della scelta.
- Forma consigliata: file Markdown con tabella di configurazione e output di verifica.
- Nomi di risorsa usati in questa soluzione: istanza `demo-web-01`, key pair `demo-key`, Security Group `demo-sg-web`.

## Prerequisiti

- Accesso attivo all'AWS Academy Learner Lab (credenziali Academy, non account AWS personale).
- Browser con AWS Management Console, oppure AWS CLI configurata con le credenziali temporanee del Learner Lab.
- Client SSH (terminale integrato, PuTTY o equivalente).
- Fallback previsto: se il Learner Lab non è raggiungibile o i crediti sono esauriti, compilare la scheda di configurazione a mano (tipo istanza, AMI, Security Group) confrontandola con la documentazione ufficiale EC2, senza avviare risorse reali.

## Scenario

- Il tuo gruppo deve pubblicare un piccolo servizio web didattico con traffico atteso basso e un budget di crediti limitato nel Learner Lab.
- Devi scegliere una AMI Amazon Linux, un tipo di istanza coerente con il carico previsto, una key pair per l'accesso SSH e un Security Group che apra solo le porte strettamente necessarie.
- Il servizio deve restare dentro i limiti del `LabRole` del Learner Lab: solo regioni abilitate (`us-east-1` o `us-west-2`), tipologie fino a `.large`, nessuna istanza Spot o Reserved.

## Step

1. Avviare il Learner Lab (**Start Lab**), attendere il pallino verde e aprire la AWS Management Console. Selezionare `us-east-1` oppure `us-west-2` e mantenere la stessa regione per le risorse collegate.
2. Aprire **EC2 → Instances → Launch instances**. Impostare **Name** = `demo-web-01`, AMI **Amazon Linux 2023**, architettura x86_64 e **Instance type** = `t3.micro`.
3. In **Key pair → Create new key pair**, creare `demo-key` di tipo **RSA**, formato **.pem**. Scaricarla e conservarla sul computer locale; impostare i permessi con i comandi della sezione seguente.
4. In **Network settings → Edit**, scegliere la **VPC di default**, una subnet con rotta verso Internet Gateway e **Auto-assign public IP → Enable**. Annotare subnet e Availability Zone. Se la VPC di default non esiste, preparare prima una rete pubblica seguendo i Lab 04 e 05.
5. Selezionare **Create security group**, nome `demo-sg-web`: inbound **SSH/TCP 22 → My IP** e **HTTP/TCP 80 → Anywhere-IPv4 (`0.0.0.0/0`)**. Lasciare l'uscita consentita per installare i pacchetti.
6. In **Configure storage**, impostare 8 GiB, tipo `gp3`; controllare il tag `Name`, il riepilogo e scegliere **Launch instance**.
7. Attendere `running` e il superamento di tutti gli status check mostrati dalla console. In **Details**, annotare Instance ID, AMI ID e **Public IPv4 address**; in **Security**, verificare il gruppo effettivamente associato.
8. Dal terminale locale collegarsi con `ssh -i ... ec2-user@...`, usando la chiave e l'IP reali. Verificare il prompt Amazon Linux e annotare l'esito.
9. Compilare il deliverable con configurazione e motivazione della scelta. Se si prosegue con il Lab 02, fermare l'istanza senza terminarla; altrimenti eseguire il cleanup completo.

## Esempio di deliverable compilato

|    # | Elemento                 | Evidenza sintetica                                                            |
| ---: | ------------------------ | ----------------------------------------------------------------------------- |
|    1 | Tipo istanza             | `t3.micro`, coerente con carico web leggero e limite `.large` del Learner Lab |
|    2 | AMI                      | Amazon Linux 2023, `ami-0abcdef1234567890` (esempio illustrativo)             |
|    3 | Key pair                 | `demo-key`, RSA, `.pem` scaricato e con permessi `chmod 400`                  |
|    4 | Security Group           | `demo-sg-web`: SSH (22) da My IP, HTTP (80) da `0.0.0.0/0`                    |
|    5 | Verifica raggiungibilità | stato `running`, tutti gli status check superati, SSH riuscito               |

## Comandi eseguiti e output

Verifica dello stato dell'istanza e recupero dell'IP pubblico (AWS CLI, in alternativa alla lettura da console):

**Ubuntu (bash) / macOS (zsh/bash)**

```bash
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=demo-web-01" \
  --query "Reservations[].Instances[].{State:State.Name,Type:InstanceType,PublicIP:PublicIpAddress}" \
  --output table
```

**Windows PowerShell**

```powershell
aws ec2 describe-instances `
  --filters "Name=tag:Name,Values=demo-web-01" `
  --query "Reservations[].Instances[].{State:State.Name,Type:InstanceType,PublicIP:PublicIpAddress}" `
  --output table
```

Output atteso (illustrativo: nel Learner Lab reale l'IP e l'ID istanza variano a ogni avvio):

```
---------------------------------------------
|             DescribeInstances              |
+-----------+----------+--------------------+
|  PublicIP |  State   |       Type         |
+-----------+----------+--------------------+
|  54.x.x.x |  running |  t3.micro          |
+-----------+----------+--------------------+
```

Connessione SSH e verifica del prompt:

**Ubuntu (bash) / macOS (zsh/bash)**

```bash
chmod 400 ~/Downloads/demo-key.pem
ssh -i ~/Downloads/demo-key.pem ec2-user@54.x.x.x
```

**Windows PowerShell**

```powershell
$key = "$env:USERPROFILE\Downloads\demo-key.pem"
icacls $key /inheritance:r
icacls $key /grant:r "${env:USERNAME}:R"
ssh -i $key ec2-user@54.x.x.x
```

Output atteso:

```
   ,     #_
   ~\_  ####_        Amazon Linux 2023
  ~~  \_#####\
[ec2-user@ip-10-0-1-25 ~]$
```

Il prompt `[ec2-user@ip-10-...]$` conferma che l'istanza è raggiungibile e che AMI, Security Group e key pair sono configurati correttamente insieme.

## Template operativo

```markdown
# Deliverable Lab 01

## Configurazione
- Nome istanza: demo-web-01
- Tipo istanza: t3.micro
- AMI: Amazon Linux 2023 (ami-...)
- Key pair: demo-key
- Security Group: demo-sg-web (22 da My IP, 80 da 0.0.0.0/0)

## Motivazione scelta tipo istanza
- Carico atteso: basso traffico didattico
- t3.micro copre il carico previsto, limita il consumo dei crediti e rispetta il limite .large del Learner Lab

## Evidenza raggiungibilità
- Stato istanza: running
- Status check: tutti gli status check superati
- SSH: connessione riuscita (prompt ec2-user@...)

## Cleanup
- Istanza fermata/terminata: si/no
- Elastic IP rilasciati: si/no/non applicabile
```

## Esempio sintetico

- Decisione corretta: `t3.micro` per un servizio a basso traffico, non un tipo più grande "per sicurezza". Un'istanza sovradimensionata consuma crediti del Learner Lab senza benefico reale per il carico previsto.
- Evidenza minima: stato `running` con status check verde, più un output SSH riuscito che mostra il prompt dell'istanza.
- Fallback accettabile: se il Learner Lab non è raggiungibile, compilare la scheda di configurazione (tipo, AMI, Security Group) confrontandola con la documentazione ufficiale, senza avviare risorse reali.
- Cleanup atteso: istanza fermata o terminata, nessun Elastic IP orfano rimasto associato.

## Checkpoint

- [x] Tipo di istanza coerente con il carico atteso ed entro il limite `.large` del Learner Lab
- [x] Security Group con solo le porte 22 (ristretta) e 80 aperte, non `0.0.0.0/0` su tutte le porte
- [x] Chiave privata `.pem` scaricata subito e con permessi corretti (`chmod 400`)
- [x] Evidenza di raggiungibilità SSH documentata
- [x] Cleanup eseguito o esplicitamente giustificato

## Errori comuni da evitare

- Scegliere un tipo di istanza superiore a `.large` (es. `t3.xlarge`): la policy del Learner Lab rifiuta la richiesta al momento dell'avvio.
- Rimandare il download della key pair: la chiave privata viene mostrata una sola volta e non può essere riscaricata.
- Aprire il Security Group a `0.0.0.0/0` su tutte le porte "per non avere problemi di connessione": espone l'istanza a scansioni automatiche.
- Dimenticare il cleanup a fine sessione: un'istanza `running` dimenticata consuma crediti anche senza traffico reale.

## Troubleshooting rapido

- Se la connessione SSH va in timeout, verifica che il Security Group apra la porta 22 e che l'istanza sia in stato `running` da almeno 1-2 minuti.
- Se il wizard rifiuta il tipo di istanza richiesto, verifica di non aver selezionato una dimensione superiore a `.large` o un'istanza Spot, non consentite dalla policy del Learner Lab.
- Se non trovi la AMI Amazon Linux, usa il filtro "Quick Start" nel wizard "Launch Instance" invece di cercarla manualmente.
- Se il Learner Lab segnala crediti insufficienti, chiudi immediatamente l'istanza e passa al fallback documentale.

## Cleanup obbligatorio

- Se prosegui con il Lab 02, usa **Stop** e conserva istanza, key pair e Security Group; documenta il riuso. Se il percorso termina qui, usa **Terminate** e rimuovi le risorse dedicate non più necessarie.
- Rilascia eventuali Elastic IP allocati manualmente durante il lab.
- Verifica in console che non restino istanze `running` non necessarie prima di chiudere la sessione del Learner Lab.
- Conferma nel deliverable che il cleanup è stato completato o indica cosa non è stato possibile rimuovere.
