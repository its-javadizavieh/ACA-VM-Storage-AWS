# Lab 04 - Concetti Base di Amazon VPC e Subnet Pubbliche/Private

## Obiettivo

- Focus operativo: pianificare e creare una VPC dedicata con una subnet pubblica e una privata, verificando la distinzione pubblica/privata dalla tabella di routing e non dal nome.
- Deliverable atteso: tabella di pianificazione CIDR, due subnet create con CIDR non sovrapposti, nota che spiega la distinzione pubblica/privata osservata.
- Nomi di risorsa usati in questa soluzione (coerenti con il Demo 04 registrato): VPC `demo-vpc`, subnet `demo-subnet-public-1a` e `demo-subnet-private-1a`.

## Prerequisiti

- Accesso attivo all'AWS Academy Learner Lab.
- AWS Management Console o AWS CLI configurata con le credenziali del Learner Lab.
- Conoscenza base della notazione CIDR (es. `/16`, `/24`).
- Fallback previsto: se il Learner Lab non è raggiungibile, disegnare lo schema CIDR su carta o tabella Markdown confrontandolo con la documentazione ufficiale VPC, senza creare risorse reali.

## Scenario

- Il tuo gruppo deve preparare la rete per un'applicazione con un livello pubblico (servizio esposto) e un livello privato (dati interni).
- Devi pianificare un CIDR di VPC che lasci spazio a subnet future, e creare almeno una subnet pubblica e una privata con CIDR non sovrapposti.
- La distinzione pubblica/privata deve basarsi sulla tabella di routing, non solo sul nome assegnato alla subnet.

## Step

1. Creare una VPC dedicata **demo-vpc** con CIDR `10.0.0.0/16` (invece di riusare la VPC di default, per costruire un'architettura di rete pulita usata anche nei lab successivi).
2. Documentare la pianificazione in una tabella prima di creare le subnet: `10.0.1.0/24` per la subnet pubblica, `10.0.2.0/24` per quella privata, entrambe in `us-east-1a`.
3. Creare la subnet **demo-subnet-public-1a** con CIDR `10.0.1.0/24`.
4. Creare la subnet **demo-subnet-private-1a** con CIDR `10.0.2.0/24`, nella stessa VPC.
5. Verificare in console la tab **Route table** di `demo-subnet-public-1a`: risulta associata alla **main route table** della VPC, che contiene solo la rotta locale `10.0.0.0/16 → local`.
6. Annotare che, a questo punto del corso, nessuna delle due subnet ha ancora una rotta verso un Internet Gateway: `demo-subnet-public-1a` è pubblica solo di nome, non ancora nella sostanza (la rotta verso l'IGW verrà aggiunta nel Lab 05).
7. Eseguire il cleanup solo se non si prosegue subito con il Lab 05, che riusa la stessa VPC e le stesse subnet.

## Esempio di deliverable compilato

|    # | Elemento                      | Evidenza sintetica                                                           |
| ---: | ----------------------------- | ---------------------------------------------------------------------------- |
|    1 | VPC                           | `demo-vpc`, CIDR `10.0.0.0/16`                                               |
|    2 | Subnet pubblica (pianificata) | `demo-subnet-public-1a`, CIDR `10.0.1.0/24`, AZ `us-east-1a`                 |
|    3 | Subnet privata                | `demo-subnet-private-1a`, CIDR `10.0.2.0/24`, AZ `us-east-1a`                |
|    4 | Route table osservata         | main route table, solo rotta locale `10.0.0.0/16 → local`, nessun IGW ancora |
|    5 | Conclusione                   | nessuna subnet è realmente pubblica finché non esiste una rotta verso l'IGW  |

## Comandi eseguiti e output

Verifica del CIDR e delle subnet create:

**Ubuntu (bash) / macOS (zsh/bash)**

```bash
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=<vpc-id-demo-vpc>" \
  --query "Subnets[].{Name:Tags[?Key=='Name']|[0].Value,CIDR:CidrBlock,AZ:AvailabilityZone}" \
  --output table
```

**Windows PowerShell**

```powershell
aws ec2 describe-subnets `
  --filters "Name=vpc-id,Values=<vpc-id-demo-vpc>" `
  --query "Subnets[].{Name:Tags[?Key=='Name']|[0].Value,CIDR:CidrBlock,AZ:AvailabilityZone}" `
  --output table
```

Output atteso (illustrativo: gli ID reali variano a ogni creazione):

```
----------------------------------------------------------------
|                       DescribeSubnets                          |
+------+-----------------------------+-------------+-------------+
|  AZ  |            Name              |    CIDR     |             |
+------+-----------------------------+-------------+-------------+
| us-east-1a | demo-subnet-public-1a  | 10.0.1.0/24 |             |
| us-east-1a | demo-subnet-private-1a | 10.0.2.0/24 |             |
+------+-----------------------------+-------------+-------------+
```

Verifica della route table associata alla subnet pubblica pianificata:

**Ubuntu (bash) / macOS (zsh/bash)**

```bash
aws ec2 describe-route-tables \
  --filters "Name=association.subnet-id,Values=<subnet-id-demo-subnet-public-1a>" \
  --query "RouteTables[].Routes"
```

**Windows PowerShell**

```powershell
aws ec2 describe-route-tables `
  --filters "Name=association.subnet-id,Values=<subnet-id-demo-subnet-public-1a>" `
  --query "RouteTables[].Routes"
```

Output atteso:

```
[
    [
        {"DestinationCidrBlock": "10.0.0.0/16", "GatewayId": "local", "State": "active"}
    ]
]
```

L'assenza di una rotta `0.0.0.0/0` conferma che, a questo stadio, nessuna subnet è realmente pubblica: la distinzione dipende dalla routing table, non dal nome assegnato.

## Template operativo

```markdown
# Deliverable Lab 04

## Pianificazione CIDR
| Nome | CIDR | AZ | Pubblica/Privata (pianificata) |
| demo-vpc | 10.0.0.0/16 | - | - |
| demo-subnet-public-1a | 10.0.1.0/24 | us-east-1a | pubblica (da completare) |
| demo-subnet-private-1a | 10.0.2.0/24 | us-east-1a | privata |

## Verifica route table
- Route table associata a demo-subnet-public-1a: main route table
- Rotte presenti: 10.0.0.0/16 -> local (nessuna rotta verso IGW)
- Conclusione: nessuna subnet è ancora pubblica nella sostanza

## Cleanup
- Subnet eliminate: si/no (mantenute per il Lab 05)
- VPC dedicata eliminata: si/no
```

## Esempio sintetico

- Decisione corretta: dichiarare che nessuna subnet è "davvero" pubblica finché la routing table non contiene una rotta verso un Internet Gateway, anche se una delle due è stata nominata `public`.
- Evidenza minima: la tabella di pianificazione CIDR più la verifica esplicita della route table, non solo l'elenco delle subnet create.
- Fallback accettabile: se il Learner Lab non è raggiungibile, disegnare lo schema CIDR su carta o tabella Markdown.
- Cleanup atteso: se non si prosegue subito con il Lab 05, eliminare le subnet e la VPC dedicata; altrimenti documentare che vengono mantenute intenzionalmente.

## Checkpoint

- [x] Il CIDR della VPC è abbastanza ampio da contenere le subnet pianificate senza sovrapposizioni
- [x] Le due subnet create hanno CIDR distinti e non sovrapposti
- [x] La distinzione pubblica/privata è motivata dalla tabella di routing osservata, non assunta dal nome

## Errori comuni da evitare

- Assumere che una subnet chiamata "pubblica" lo sia realmente, senza verificare la sua routing table.
- Scegliere un CIDR di VPC troppo piccolo, che non lascia spazio a subnet future.
- Creare due subnet con CIDR sovrapposti nella stessa VPC, causando un errore di creazione.
- Dimenticare di documentare che la rotta verso Internet non esiste ancora a questo stadio del corso.

## Troubleshooting rapido

- Se la creazione della subnet fallisce per sovrapposizione di CIDR, verifica gli intervalli già occupati da altre subnet nella VPC.
- Se non è chiaro quale tabella di routing è associata a una subnet, controlla la scheda "Route Table" nella console EC2/VPC per quella subnet specifica.
- Se la VPC del Learner Lab ha già molte subnet esistenti, usa un intervallo CIDR libero documentato prima di crearne di nuove.
- Se non riesci a determinare se una subnet è pubblica, ricorda che serve una rotta esplicita verso un Internet Gateway nella sua tabella di routing (verrà configurata nella Lezione 05).

## Cleanup obbligatorio

- Elimina le subnet create per l'esercitazione, se non più necessarie.
- Se hai creato una VPC dedicata (non quella di default del Learner Lab), eliminala al termine del lab.
- Verifica che non restino subnet orfane con CIDR sovrapposti che potrebbero confondere lab successivi.
- Conferma nel deliverable che il cleanup è stato completato o indica cosa non è stato possibile rimuovere.
