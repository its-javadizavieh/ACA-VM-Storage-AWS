# Lab 06 - Security Group, Network ACL e Architetture di Rete Sicure

## Obiettivo

- Focus operativo: applicare il minimo privilegio ai Security Group dell'architettura esistente e aggiungere una Network ACL personalizzata alla subnet privata, verificandone il comportamento stateless.
- Deliverable atteso: Security Group senza regole `0.0.0.0/0` non necessarie, NACL personalizzata con regole di permesso e negazione, tabella di documentazione delle regole.
- Nomi di risorsa usati in questa soluzione (coerenti con il Demo 06 registrato): Network ACL `demo-nacl-private`, Security Group `demo-sg-bastion` (dal Lab 05) e `demo-sg-private` (istanza applicativa, dal Lab 05).

## Prerequisiti

- Accesso attivo all'AWS Academy Learner Lab, con la rete (VPC, subnet, Bastion Host) dei Lab 04/05 o equivalenti.
- AWS Management Console o AWS CLI configurata con le credenziali del Learner Lab.
- Conoscenza base di Security Group, tabelle di routing e concetto di regole stateful/stateless.
- Fallback previsto: se il Learner Lab non è raggiungibile, documentare le regole pianificate (porta, protocollo, origine, motivazione) su tabella Markdown, senza creare risorse reali.

## Scenario

- Il tuo gruppo deve proteggere l'architettura multi-livello costruita nelle lezioni precedenti, applicando il principio del minimo privilegio.
- Devi configurare il Security Group dell'istanza applicativa per accettare traffico solo dal load balancer sulla porta applicativa, e SSH solo dal Bastion Host.
- Devi aggiungere una Network ACL personalizzata alla subnet privata e verificarne il comportamento stateless, includendo la regola di uscita necessaria per il traffico di risposta.

## Step

1. Verificare `demo-sg-private` (Security Group dell'istanza applicativa/privata dal Lab 05): confermare che accetta SSH solo dal Security Group `demo-sg-bastion`, non da un CIDR generico.
2. Creare la Network ACL personalizzata **demo-nacl-private** in `demo-vpc` e associarla esplicitamente a `demo-subnet-private-1a`.
3. Aggiungere la regola inbound 100: **Allow** SSH (22) da `10.0.1.0/24` (CIDR della subnet pubblica, da dove arriva il traffico del Bastion Host).
4. Provare subito il salto SSH da `demo-bastion`: la connessione va in timeout perché manca la regola di uscita.
5. Aggiungere la regola outbound 100: **Allow** porte effimere (1024-65535) verso `10.0.1.0/24`, necessaria per il traffico di risposta (la NACL è stateless).
6. Riprovare il salto SSH: ora funziona, confermando la differenza pratica rispetto al Security Group (stateful, non richiede regola di risposta).
7. Dimostrare la priorità delle regole aggiungendo temporaneamente una regola 50 che nega tutto da `10.0.1.0/24`: il traffico si blocca di nuovo perché la regola 50 viene valutata prima della 100. Rimuovere questa regola di test al termine della verifica.
8. Documentare ogni regola (Security Group e NACL) con porta, protocollo, origine e motivazione, poi eseguire il cleanup.

## Esempio di deliverable compilato

|    # | Elemento                 | Evidenza sintetica                                                           |
| ---: | ------------------------ | ---------------------------------------------------------------------------- |
|    1 | SG istanza applicativa   | `demo-sg-private`: SSH solo da `demo-sg-bastion`, nessuna regola `0.0.0.0/0` |
|    2 | NACL personalizzata      | `demo-nacl-private`, associata a `demo-subnet-private-1a`                    |
|    3 | Regola inbound 100       | Allow SSH (22) da `10.0.1.0/24`                                              |
|    4 | Regola outbound 100      | Allow porte 1024-65535 verso `10.0.1.0/24` (risposta stateless)              |
|    5 | Verifica priorità regole | regola 50 (deny) valutata prima della 100 (allow); rimossa dopo il test      |

## Comandi eseguiti e output

Verifica delle regole della NACL personalizzata:

**Ubuntu (bash) / macOS (zsh/bash)**

```bash
aws ec2 describe-network-acls \
  --filters "Name=tag:Name,Values=demo-nacl-private" \
  --query "NetworkAcls[].Entries"
```

**Windows PowerShell**

```powershell
aws ec2 describe-network-acls `
  --filters "Name=tag:Name,Values=demo-nacl-private" `
  --query "NetworkAcls[].Entries"
```

Output atteso (illustrativo: l'ID NACL varia a ogni creazione reale):

```
[
    [
        {"RuleNumber": 100, "Protocol": "6", "PortRange": {"From": 22, "To": 22}, "CidrBlock": "10.0.1.0/24", "RuleAction": "allow", "Egress": false},
        {"RuleNumber": 100, "Protocol": "6", "PortRange": {"From": 1024, "To": 65535}, "CidrBlock": "10.0.1.0/24", "RuleAction": "allow", "Egress": true}
    ]
]
```

Verifica del salto SSH da `demo-bastion` verso `demo-private-test` prima e dopo la regola outbound:

**Ubuntu (bash) / macOS (zsh/bash)**

```bash
ssh -i ~/demo-key.pem -o ConnectTimeout=5 ec2-user@10.0.2.15
```

**Windows PowerShell**

```powershell
$key = "$env:USERPROFILE\Downloads\demo-key.pem"
ssh -i $key -o ConnectTimeout=5 ec2-user@10.0.2.15
```

Output atteso **prima** della regola outbound 100 (solo inbound presente):

```
ssh: connect to host 10.0.2.15 port 22: Connection timed out
```

Output atteso **dopo** aver aggiunto la regola outbound 100:

```
[ec2-user@ip-10-0-2-15 ~]$
```

La differenza tra i due output conferma concretamente la natura stateless della NACL: permettere l'entrata non basta, serve una regola esplicita anche per il traffico di risposta.

## Template operativo

```markdown
# Deliverable Lab 06

## Security Group istanza applicativa (demo-sg-private)
| Porta | Protocollo | Origine | Motivazione |
| 22 | TCP | SG demo-sg-bastion | accesso amministrativo solo dal Bastion Host |

## Network ACL (demo-nacl-private) - subnet demo-subnet-private-1a
| Direzione | Regola # | Protocollo | Porta | CIDR | Azione |
| Inbound | 100 | TCP | 22 | 10.0.1.0/24 | Allow |
| Outbound | 100 | TCP | 1024-65535 | 10.0.1.0/24 | Allow |

## Verifica priorità regole
- Regola 50 (deny, test): traffico bloccato -> conferma che regola 50 è valutata prima della 100
- Regola 50 rimossa dopo il test

## Cleanup
- Regole di test troppo permissive rimosse: si/no
- NACL personalizzata ripristinata a default o eliminata: si/no
```

## Esempio sintetico

- Decisione corretta: aggiungere sempre la regola outbound corrispondente quando si crea una regola inbound su una NACL, perché il comportamento stateless non la genera automaticamente come farebbe un Security Group.
- Evidenza minima: il confronto diretto tra il tentativo di connessione fallito (solo inbound) e quello riuscito (inbound + outbound), non solo la configurazione finale.
- Fallback accettabile: se il Learner Lab non è raggiungibile, documentare le regole pianificate (porta, protocollo, origine, motivazione) su tabella Markdown.
- Cleanup atteso: regole di test permissive rimosse, NACL personalizzata ripristinata o eliminata se non serve ai lab successivi.

## Checkpoint

- [x] Nessuna regola di Security Group o NACL usa `0.0.0.0/0` su porte sensibili senza motivazione esplicita
- [x] La NACL personalizzata include sia la regola di entrata sia quella di uscita necessarie per il traffico di risposta
- [x] Il traffico legittimo (Bastion Host verso istanza privata) continua a funzionare dopo le modifiche
- [x] Cleanup delle regole di test eseguito o giustificato

## Errori comuni da evitare

- Aggiungere una regola inbound alla NACL senza la corrispondente regola outbound, causando un blocco del traffico di risposta che sembra un problema "misterioso".
- Assumere che il Security Group richieda lo stesso trattamento della NACL: è stateful e non serve una regola di risposta esplicita.
- Numerare le regole NACL senza margine (es. 1, 2, 3), rendendo difficile inserire eccezioni future senza rinumerare tutto.
- Lasciare la regola di negazione di test (usata per dimostrare la priorità) attiva dopo la verifica.

## Troubleshooting rapido

- Se il traffico legittimo smette di funzionare dopo aver aggiunto la NACL, verifica di aver incluso anche la regola di uscita per la risposta (la NACL è stateless, a differenza del Security Group).
- Se una regola di negazione NACL blocca più traffico del previsto, controlla il numero di regola: una regola di negazione con numero più basso di una regola di permesso viene valutata per prima.
- Se il Security Group dell'istanza applicativa rifiuta il traffico dal load balancer, verifica di aver referenziato il Security Group del load balancer come origine, non un CIDR generico.
- Se non è chiaro quale regola sta bloccando il traffico, controlla nell'ordine: routing table, Security Group, Network ACL (in entrambe le direzioni).

## Cleanup obbligatorio

- Rimuovi le regole di test troppo permissive (`0.0.0.0/0`) create per velocizzare le verifiche durante il lab.
- Se la Network ACL personalizzata è stata creata solo per l'esercitazione, ripristina l'associazione della subnet alla NACL di default ed eliminala.
- Verifica che i Security Group non contengano regole residue non documentate.
- Conferma nel deliverable che il cleanup è stato completato o indica cosa non è stato possibile rimuovere.
