# Lab 01 - Istanze EC2: Creazione, Configurazione e Tipologie

## Obiettivo

- Avviare un'istanza EC2 scegliendo tipo, AMI, key pair e Security Group coerenti con uno scenario a basso traffico.
- Collegare il risultato pratico ai micro-argomenti: creazione e configurazione di istanze EC2, tipologie di istanze e relativi use case.

## Durata (timebox)

- 30 minuti.
- 5 minuti setup e lettura scenario.
- 20 minuti esecuzione guidata.
- 5 minuti checkpoint, cleanup e consegna evidenze.

## Prerequisiti

- Accesso attivo all'AWS Academy Learner Lab (credenziali Academy, non account AWS personale).
- Browser con AWS Management Console, oppure AWS CLI configurata con le credenziali temporanee del Learner Lab.
- Client SSH (terminale integrato, PuTTY o equivalente).
- Fallback previsto: se il Learner Lab non è raggiungibile o i crediti sono esauriti, compilare la scheda di configurazione a mano (tipo istanza, AMI, Security Group) confrontandola con la documentazione ufficiale EC2, senza avviare risorse reali.

## Scenario

- Il tuo gruppo deve pubblicare un piccolo servizio web didattico con traffico atteso basso e un budget di crediti limitato nel Learner Lab.
- Devi scegliere una AMI Amazon Linux, un tipo di istanza coerente con il carico previsto, una key pair per l'accesso SSH e un Security Group che apra solo le porte strettamente necessarie.
- Il servizio deve restare dentro i limiti del `LabRole` del Learner Lab: solo regioni abilitate (`us-east-1` o `us-west-2`), tipologie fino a `.large`, nessuna istanza Spot o Reserved.

## Step (numerati)

1. Accedi al Learner Lab, avvia il modulo (`Start Lab`) e apri la AWS Management Console dalla voce `AWS`.
2. In EC2, avvia il wizard "Launch Instance": scegli una AMI Amazon Linux (2023 o equivalente disponibile) e il tipo di istanza `t3.micro`, motivando la scelta rispetto al carico atteso.
3. Crea (o riusa) una key pair, scarica il file `.pem` e imposta subito i permessi corretti (`chmod 400`).
4. Configura un Security Group che apra solo la porta 22 (SSH, ristretta al tuo IP se possibile) e la porta 80 (HTTP).
5. Avvia l'istanza, attendi lo stato `running` e recupera l'indirizzo IP pubblico dalla console o con `aws ec2 describe-instances`.
6. Connettiti in SSH all'istanza e verifica che risulti raggiungibile; annota tipo istanza, AMI ID, Security Group e motivazione della scelta.
7. Esegui il cleanup (Step 6 della sezione dedicata) e conferma nel deliverable che l'istanza è stata fermata o terminata.

## Output atteso

- Un'istanza EC2 `running` (poi fermata/terminata) con tipo, AMI ID e Security Group documentati.
- Evidenza della connessione SSH riuscita (screenshot o output del comando).
- Una nota di 2-3 frasi che motiva la scelta del tipo di istanza rispetto allo scenario a basso traffico.

## Checkpoint

- Il tipo di istanza scelto è coerente con il carico atteso (non sovradimensionato) ed è entro i limiti del Learner Lab (`.large` massimo).
- Il Security Group apre solo le porte strettamente necessarie (22 e 80), non tutte le porte a `0.0.0.0/0`.
- La chiave privata `.pem` è stata scaricata e conservata correttamente, non condivisa con altri.

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
