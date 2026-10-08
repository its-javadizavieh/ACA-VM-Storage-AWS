# Lab 05 - Routing Tables, Internet Gateway, NAT Gateway e Bastion Host

## Obiettivo

- Focus operativo: completare la connettività della VPC `demo-vpc` (dal Lab 04) con Internet Gateway per la subnet pubblica, NAT Gateway per quella privata, e un Bastion Host come unico punto di accesso SSH.
- Deliverable atteso: routing corretto su entrambe le subnet, salto SSH riuscito verso l'istanza privata, evidenza di connettività in uscita tramite NAT Gateway.
- Nomi di risorsa usati in questa soluzione (coerenti con il Demo 05 registrato): Internet Gateway `demo-igw`, NAT Gateway `demo-nat`, Bastion Host `demo-bastion` (SG `demo-sg-bastion`), istanza privata di test `demo-private-test` (SG `demo-sg-private`).

## Prerequisiti

- Accesso attivo all'AWS Academy Learner Lab, con la VPC e le subnet pubblica/privata del Lab 04 (o equivalenti create al momento).
- AWS Management Console o AWS CLI configurata con le credenziali del Learner Lab.
- Una key pair disponibile per l'accesso SSH al Bastion Host e all'istanza privata.
- Fallback previsto: se il Learner Lab non è raggiungibile, disegnare lo schema di routing (IGW, NAT Gateway, Bastion Host) su Markdown confrontandolo con la documentazione ufficiale, senza creare risorse reali.

## Scenario

- Il tuo gruppo ha una VPC con subnet pubblica e privata e deve completare la connettività: la subnet pubblica deve raggiungere Internet in entrata/uscita, la subnet privata solo in uscita.
- Devi creare un Internet Gateway per la subnet pubblica e un NAT Gateway per la subnet privata, e verificare che le rotte siano corrette.
- Devi lanciare un Bastion Host in subnet pubblica e usarlo come unico punto di accesso SSH verso un'istanza in subnet privata.

## Step

1. Creare l'Internet Gateway **demo-igw**, collegarlo a `demo-vpc`, e aggiungere la rotta `0.0.0.0/0 → demo-igw` a una route table dedicata associata a `demo-subnet-public-1a`.
2. Lanciare l'istanza privata **demo-private-test** in `demo-subnet-private-1a`, con Security Group **demo-sg-private** che accetta SSH solo dal Security Group del Bastion Host (non da un IP, ma dal SG stesso).
3. Allocare un Elastic IP e creare il NAT Gateway **demo-nat** in `demo-subnet-public-1a`, associato all'Elastic IP.
4. Aggiungere la rotta `0.0.0.0/0 → demo-nat` alla route table di `demo-subnet-private-1a`.
5. Lanciare il Bastion Host **demo-bastion** in subnet pubblica, con Security Group **demo-sg-bastion** che accetta SSH solo dal proprio IP (My IP), non da `0.0.0.0/0`.
6. Connettersi in SSH a `demo-bastion`, poi effettuare il salto verso `demo-private-test` usando il suo IP privato.
7. Verificare la connettività in uscita dell'istanza privata (`curl` verso un host pubblico) tramite il NAT Gateway, poi eseguire il cleanup.

## Esempio di deliverable compilato

|    # | Elemento             | Evidenza sintetica                                                       |
| ---: | -------------------- | ------------------------------------------------------------------------ |
|    1 | Internet Gateway     | `demo-igw`, collegato a `demo-vpc`, rotta `0.0.0.0/0` su subnet pubblica |
|    2 | NAT Gateway          | `demo-nat`, in `demo-subnet-public-1a`, Elastic IP associato             |
|    3 | Rotta subnet privata | `0.0.0.0/0 → demo-nat` nella route table di `demo-subnet-private-1a`     |
|    4 | Bastion Host         | `demo-bastion`, SG `demo-sg-bastion` (SSH solo da My IP)                 |
|    5 | Salto SSH riuscito   | da `demo-bastion` a `demo-private-test` via IP privato                   |

## Comandi eseguiti e output

Verifica delle rotte su entrambe le subnet dopo la configurazione:

**Ubuntu (bash) / macOS (zsh/bash)**

```bash
aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=<vpc-id-demo-vpc>" \
  --query "RouteTables[].Routes[?DestinationCidrBlock=='0.0.0.0/0']"
```

**Windows PowerShell**

```powershell
aws ec2 describe-route-tables `
  --filters "Name=vpc-id,Values=<vpc-id-demo-vpc>" `
  --query "RouteTables[].Routes[?DestinationCidrBlock=='0.0.0.0/0']"
```

Output atteso (illustrativo: gli ID gateway variano a ogni creazione reale):

```
[
    [{"DestinationCidrBlock": "0.0.0.0/0", "GatewayId": "igw-0demo123", "State": "active"}],
    [{"DestinationCidrBlock": "0.0.0.0/0", "NatGatewayId": "nat-0demo456", "State": "active"}]
]
```

Salto SSH da `demo-bastion` verso `demo-private-test` (eseguito nel terminale connesso al Bastion Host):

**Ubuntu (bash) / macOS (zsh/bash)**

```bash
ssh -i ~/demo-key.pem ec2-user@10.0.2.15
```

**Windows PowerShell**

```powershell
$key = "$env:USERPROFILE\Downloads\demo-key.pem"
ssh -i $key ec2-user@10.0.2.15
```

Output atteso:

```
[ec2-user@ip-10-0-2-15 ~]$
```

Verifica della connettività in uscita dell'istanza privata tramite NAT Gateway:

**Ubuntu (bash) / macOS (zsh/bash)**

```bash
curl -Is https://aws.amazon.com | head -1
```

**Windows PowerShell**

```powershell
(Invoke-WebRequest -Uri https://aws.amazon.com -Method Head).StatusCode
```

Output atteso:

```
HTTP/2 200
```

Le due rotte `0.0.0.0/0` (una verso `igw-...`, una verso `nat-...`) confermano che la subnet pubblica ha accesso bidirezionale mentre quella privata ha accesso solo in uscita; il prompt SSH e la risposta HTTP confermano rispettivamente l'accesso amministrativo controllato e la connettività in uscita.

## Template operativo

```markdown
# Deliverable Lab 05

## Rotte
- Subnet pubblica: 0.0.0.0/0 -> demo-igw
- Subnet privata: 0.0.0.0/0 -> demo-nat

## Bastion Host
- Nome: demo-bastion
- Security Group: demo-sg-bastion (SSH solo da My IP)

## Istanza privata di test
- Nome: demo-private-test
- Security Group: demo-sg-private (SSH solo dal SG del Bastion Host)

## Evidenza
- Salto SSH riuscito: si (prompt ec2-user@ip-10-0-2-...)
- Connettività in uscita verificata: si (curl -> HTTP/2 200)

## Cleanup
- NAT Gateway eliminato ed Elastic IP rilasciato: si/no
- Bastion Host e istanza privata terminati: si/no
- Internet Gateway scollegato ed eliminato (se creato ad hoc): si/no
```

## Esempio sintetico

- Decisione corretta: il Security Group dell'istanza privata accetta SSH solo dal Security Group del Bastion Host (non da un IP), così la regola resta valida anche se l'IP del Bastion cambia.
- Evidenza minima: rotte `0.0.0.0/0` verificate su entrambe le subnet, più il salto SSH riuscito e la connettività in uscita confermata.
- Fallback accettabile: se il Learner Lab non è raggiungibile, disegnare lo schema di routing (IGW, NAT, Bastion) su Markdown.
- Cleanup atteso: NAT Gateway eliminato (richiede alcuni minuti) con Elastic IP rilasciato, Bastion Host e istanza privata terminati.

## Checkpoint

- [x] Routing table della subnet pubblica con rotta verso l'Internet Gateway
- [x] Routing table della subnet privata con rotta verso il NAT Gateway
- [x] Bastion Host con SSH ristretto a IP specifici, non `0.0.0.0/0`
- [x] Istanza privata con SSH ristretto al Security Group del Bastion Host
- [x] Cleanup (NAT Gateway, Elastic IP, Bastion Host, istanza privata) eseguito o giustificato

## Errori comuni da evitare

- Confondere il ruolo di IGW (bidirezionale, subnet pubblica) e NAT Gateway (solo uscita, subnet privata).
- Aprire il Security Group del Bastion Host a `0.0.0.0/0` "per comodità di accesso da più luoghi".
- Dimenticare che il NAT Gateway richiede alcuni minuti per diventare `available` prima di poter instradare traffico.
- Lasciare il NAT Gateway attivo dopo il lab: genera un costo orario continuo indipendentemente dal traffico.

## Troubleshooting rapido

- Se l'istanza pubblica non risponde, verifica prima la routing table (rotta verso IGW) e solo dopo il Security Group.
- Se l'istanza privata non ha accesso a Internet in uscita, verifica che il NAT Gateway sia nello stato `available` e che la rotta `0.0.0.0/0` punti a esso, non all'IGW.
- Se il salto SSH dal Bastion Host verso l'istanza privata fallisce, verifica che la chiave privata sia presente sul Bastion Host o usa l'agent forwarding SSH.
- Se il NAT Gateway resta a lungo in stato `pending`, attendi qualche minuto: la creazione richiede tempo prima di poter instradare traffico.

## Cleanup obbligatorio

- Elimina il NAT Gateway creato per il test (l'eliminazione richiede alcuni minuti per completarsi).
- Rilascia l'Elastic IP associato al NAT Gateway una volta eliminato.
- Termina il Bastion Host e l'istanza privata create per l'esercitazione.
- Se l'Internet Gateway è stato creato ad hoc, scollegalo dalla VPC ed eliminalo.
- Conferma nel deliverable che il cleanup è stato completato o indica cosa non è stato possibile rimuovere.
