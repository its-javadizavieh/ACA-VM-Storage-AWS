# Lab 01 - Istanze EC2: Creazione, Configurazione e Tipologie

## Obiettivo

- Focus operativo: avviare un'istanza EC2 coerente con uno scenario a basso traffico e budget limitato, scegliendo tipo, AMI, key pair e Security Group corretti, poi verificarne la raggiungibilità in SSH.
- Deliverable atteso: istanza `running` (poi fermata/terminata) con tipo, AMI ID e Security Group documentati, evidenza SSH riuscita, nota di motivazione della scelta.
- Forma consigliata: file Markdown con tabella di configurazione e output di verifica.
- Nomi di risorsa usati in questa soluzione (coerenti con il Demo 01 registrato): istanza `demo-web-01`, key pair `demo-key`, Security Group `demo-sg-web`.

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

1. Avviare il Learner Lab (**Start Lab**) e attendere il pallino verde prima di aprire la AWS Management Console.
2. In EC2 → **Instances** → **Launch instances**, impostare **Name** = `demo-web-01` e lasciare selezionata l'AMI **Amazon Linux 2023** (prima opzione proposta, Free tier eligible).
3. Nella sezione **Instance type**, selezionare `t3.micro`: coerente con un servizio web a basso traffico e ben dentro il limite `.large` della policy del Learner Lab.
4. Creare una key pair **demo-key** (tipo RSA, formato `.pem`), scaricarla immediatamente e impostare i permessi con `chmod 400`.
5. In **Network settings**, creare un Security Group **demo-sg-web** con due sole regole inbound: SSH (porta 22) ristretta a **My IP**, HTTP (porta 80) aperta a `0.0.0.0/0`.
6. Lasciare lo storage di default (8 GiB, `gp3`), aggiungere il tag `Name = demo-web-01`, controllare il riepilogo e cliccare **Launch instance**.
7. Attendere lo stato `running` e il **Status check** `2/2 checks passed`, poi recuperare il **Public IPv4 address** dal tab Details.
8. Connettersi in SSH e verificare che il prompt di Amazon Linux compaia correttamente.
9. Documentare tipo istanza, AMI ID, Security Group e motivazione, poi eseguire il cleanup.

## Esempio di deliverable compilato

|    # | Elemento                 | Evidenza sintetica                                                            |
| ---: | ------------------------ | ----------------------------------------------------------------------------- |
|    1 | Tipo istanza             | `t3.micro`, coerente con carico web leggero e limite `.large` del Learner Lab |
|    2 | AMI                      | Amazon Linux 2023, `ami-0abcdef1234567890` (esempio illustrativo)             |
|    3 | Key pair                 | `demo-key`, RSA, `.pem` scaricato e con permessi `chmod 400`                  |
|    4 | Security Group           | `demo-sg-web`: SSH (22) da My IP, HTTP (80) da `0.0.0.0/0`                    |
|    5 | Verifica raggiungibilità | stato `running`, status check `2/2 checks passed`, SSH riuscito               |

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
- t3.micro copre il carico previsto, resta nel Free Tier e rispetta il limite .large del Learner Lab

## Evidenza raggiungibilità
- Stato istanza: running
- Status check: 2/2 checks passed
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

- Ferma (`Stop`) o termina (`Terminate`) l'istanza EC2 creata per l'esercitazione.
- Rilascia eventuali Elastic IP allocati manualmente durante il lab.
- Verifica in console che non restino istanze `running` non necessarie prima di chiudere la sessione del Learner Lab.
- Conferma nel deliverable che il cleanup è stato completato o indica cosa non è stato possibile rimuovere.
