# Lab 04 - Concetti Base di Amazon VPC e Subnet Pubbliche/Private

## Obiettivo

- Focus operativo: pianificare e creare una VPC dedicata con una subnet pubblica e una privata, verificando la distinzione pubblica/privata dalla tabella di routing e non dal nome.
- Deliverable atteso: tabella di pianificazione CIDR, due subnet create con CIDR non sovrapposti, nota che spiega la distinzione pubblica/privata osservata.
- Nomi di risorsa usati in questa soluzione: VPC `demo-vpc`, subnet `demo-subnet-public-1a` e `demo-subnet-private-1a`.

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

1. Selezionare la regione di lavoro (`us-east-1` negli esempi). Aprire **VPC → Your VPCs → Create VPC**, scegliere **VPC only**, nome `demo-vpc`, IPv4 CIDR `10.0.0.0/16`, **Tenancy → Default**, quindi **Create VPC**. Questa rete è separata dalla VPC di default dei Lab 01–03.
2. Prima di creare le subnet, documentare `10.0.1.0/24` per il livello pubblico e `10.0.2.0/24` per quello privato, entrambe in `us-east-1a`. Se si usa un'altra regione, scegliere un'AZ disponibile e adattare nomi e tabella.
3. Aprire **Subnets → Create subnet**, selezionare `demo-vpc` e aggiungere `demo-subnet-public-1a`, AZ `us-east-1a`, CIDR `10.0.1.0/24`.
4. Con **Add new subnet**, aggiungere `demo-subnet-private-1a`, stessa AZ, CIDR `10.0.2.0/24`; scegliere **Create subnet**.
5. In **Route Tables**, individuare la tabella con **Main = Yes** appartenente a `demo-vpc`. In **Routes**, verificare la sola rotta `10.0.0.0/16 → local`.
6. In **Subnets**, selezionare ciascuna subnet e aprire **Route table**: entrambe usano implicitamente la main route table finché non si assegna una tabella diversa.
7. Annotare che nessuna subnet ha ancora una rotta verso Internet Gateway: `public` è per ora solo un nome. Conservare VPC e subnet per il Lab 05 oppure eseguire il cleanup se il percorso termina qui.

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

Verifica della main route table usata implicitamente dalle due subnet. Il filtro per associazione esplicita alla subnet non la troverebbe in questa fase:

**Ubuntu (bash) / macOS (zsh/bash)**

```bash
aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=<vpc-id-demo-vpc>" "Name=association.main,Values=true" \
  --query "RouteTables[].Routes"
```

**Windows PowerShell**

```powershell
aws ec2 describe-route-tables `
  --filters "Name=vpc-id,Values=<vpc-id-demo-vpc>" "Name=association.main,Values=true" `
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
- Conserva `demo-vpc` e le due subnet se prosegui con il Lab 05; altrimenti elimina le subnet e poi la VPC dedicata.
- Verifica che non restino subnet orfane con CIDR sovrapposti che potrebbero confondere lab successivi.
- Conferma nel deliverable che il cleanup è stato completato o indica cosa non è stato possibile rimuovere.
