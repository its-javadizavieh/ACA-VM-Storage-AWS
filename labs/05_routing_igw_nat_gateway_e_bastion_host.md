# Lab 05 - Routing Tables, Internet Gateway, NAT Gateway e Bastion Host

## Obiettivo

- Focus operativo: completare la connettività della VPC `demo-vpc` (dal Lab 04) con Internet Gateway per la subnet pubblica, NAT Gateway per quella privata, e un Bastion Host come unico punto di accesso SSH.
- Deliverable atteso: routing corretto su entrambe le subnet, salto SSH riuscito verso l'istanza privata, evidenza di connettività in uscita tramite NAT Gateway.
- Nomi di risorsa usati in questa soluzione: Internet Gateway `demo-igw`, NAT Gateway `demo-nat`, Bastion Host `demo-bastion` (SG `demo-sg-bastion`), istanza privata di test `demo-private-test` (SG `demo-sg-private`).

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

1. Aprire **VPC → Internet Gateways → Create internet gateway**, nome `demo-igw`. Dopo la creazione scegliere **Actions → Attach to VPC → demo-vpc**.
2. In **Route Tables → Create route table**, creare `demo-rt-public` in `demo-vpc`. In **Routes → Edit routes → Add route**, aggiungere `0.0.0.0/0 → Internet Gateway → demo-igw` e salvare.
3. In **Subnet associations → Edit subnet associations**, selezionare solo `demo-subnet-public-1a` e salvare. Verificare dalla subnet che la tabella associata sia `demo-rt-public`.
4. In **Elastic IPs → Allocate Elastic IP address**, allocare un indirizzo. In **NAT Gateways → Create NAT gateway**, impostare `demo-nat`, subnet `demo-subnet-public-1a`, connettività **Public** e l'Elastic IP appena allocato. Attendere `available`.
5. Aprire **Subnets → demo-subnet-private-1a → Route table**. Sulla main route table ancora associata alla subnet privata aggiungere `0.0.0.0/0 → NAT Gateway → demo-nat`. Verificare che la subnet pubblica continui a usare `demo-rt-public`.
6. In **EC2 → Launch instances**, creare prima `demo-bastion`: Amazon Linux 2023, `t3.micro`, key pair `demo-key`, VPC `demo-vpc`, subnet `demo-subnet-public-1a`, **Auto-assign public IP → Enable**. Creare `demo-sg-bastion` nella stessa VPC con inbound SSH/TCP 22 da **My IP**.
7. Creare `demo-private-test`: Amazon Linux 2023, `t3.micro`, stessa key pair, VPC `demo-vpc`, subnet `demo-subnet-private-1a`, **Auto-assign public IP → Disable**. Creare `demo-sg-private` con inbound SSH/TCP 22, **Source → Custom → demo-sg-bastion**. Lasciare l'uscita necessaria per SSH dal bastion e HTTPS dall'istanza privata.
8. Attendere tutti gli status check. Annotare IP pubblico del bastion e IP privato dell'istanza di test; verificare che quest'ultima non abbia IP pubblico.
9. Dal computer locale usare la configurazione SSH sotto per raggiungere l'istanza privata passando dal bastion. Verificare il nome dell'host con `hostname`.
10. Nella sessione SSH dell'istanza privata eseguire `curl -I https://aws.amazon.com`: una risposta HTTP conferma l'uscita via NAT. Documentare rotte, associazioni, Security Group e risultati.
11. Se si prosegue subito con il Lab 06, conservare entrambe le istanze e la rete. Eliminare il NAT Gateway e rilasciare il suo Elastic IP appena l'accesso Internet dalla subnet privata non serve più; completare il cleanup al termine della sequenza.

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

Accesso dal computer locale tramite bastion, usando OpenSSH su Ubuntu, macOS o Windows PowerShell. Creare/modificare `~/.ssh/config` (Windows: `$env:USERPROFILE\.ssh\config`) aggiungendo questi alias; sostituire gli IP con quelli reali:

```sshconfig
Host lab-bastion
    HostName IP_PUBBLICO_BASTION
    User ec2-user
    IdentityFile ~/Downloads/demo-key.pem
    IdentitiesOnly yes

Host lab-private
    HostName IP_PRIVATO_ISTANZA
    User ec2-user
    IdentityFile ~/Downloads/demo-key.pem
    IdentitiesOnly yes
    ProxyJump lab-bastion
```

Dopo aver salvato `~/.ssh/config`, impostare i permessi della chiave e del file di configurazione dal terminale **locale Ubuntu (bash) / macOS (zsh/bash)**:

```bash
chmod 400 ~/Downloads/demo-key.pem
chmod 600 ~/.ssh/config
```

Dal terminale **locale**, collegarsi in SSH:

```bash
ssh lab-bastion
# Verificare il prompt del bastion, poi tornare al computer locale:
exit
ssh lab-private
```

`ProxyJump` usa il bastion per il collegamento; la chiave privata resta sul computer locale. Nella sessione dell'istanza privata eseguire i seguenti comandi Linux, anche se il terminale locale è PowerShell:

```bash
hostname
curl -I https://aws.amazon.com
```

Risultato atteso: hostname privato (ad esempio `ip-10-0-2-15`) e una risposta HTTP, per esempio `HTTP/2 200`. Gli IP e la versione HTTP possono variare.

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
- Cleanup atteso: NAT Gateway eliminato (richiede alcuni minuti) con Elastic IP rilasciato; bastion e istanza privata mantenuti solo se si prosegue subito con il Lab 06, altrimenti terminati.

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
- Se il salto SSH fallisce, verifica prima `ssh lab-bastion`, poi gli IP, il percorso locale della chiave e la regola SSH da `demo-sg-bastion` a `demo-sg-private`.
- Se il NAT Gateway resta a lungo in stato `pending`, attendi qualche minuto: la creazione richiede tempo prima di poter instradare traffico.

## Cleanup obbligatorio

Se prosegui subito con il Lab 06, conserva bastion, istanza privata, VPC, subnet e Internet Gateway; il test NACL richiede entrambe le istanze. Documenta il riuso. Al termine della sequenza applica tutti i passaggi seguenti.

- Elimina il NAT Gateway creato per il test (l'eliminazione richiede alcuni minuti per completarsi).
- Rilascia l'Elastic IP associato al NAT Gateway una volta eliminato.
- Rimuovi dalla tabella privata la rotta verso il NAT Gateway eliminato, per non lasciare una rotta `blackhole`.
- Termina il Bastion Host e l'istanza privata create per l'esercitazione.
- Se l'Internet Gateway è stato creato ad hoc, scollegalo dalla VPC ed eliminalo.
- Conferma nel deliverable che il cleanup è stato completato o indica cosa non è stato possibile rimuovere.
