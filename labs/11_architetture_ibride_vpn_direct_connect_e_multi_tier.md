# Lab 11 - Architetture Ibride (VPN/Direct Connect) e Multi-Tier

## Obiettivo

- Focus operativo: progettare la separazione multi-tier (web, application, database) con Security Group a catena a minimo privilegio, e configurare (dimostrativamente) una VPN Site-to-Site verso una rete on-premises simulata.
- Deliverable atteso: tabella multi-tier con Security Group documentati, Virtual Private Gateway e VPN Connection creati o documentati, nota di scelta tra VPN e Direct Connect.
- Nomi di risorsa usati in questa soluzione: Customer Gateway `demo-cgw`, Virtual Private Gateway `demo-vgw`, VPN Connection `demo-vpn`, Security Group `demo-sg-tier-web`/`demo-sg-tier-app`/`demo-sg-tier-db`.

## Prerequisiti

- Accesso attivo all'AWS Academy Learner Lab, con la rete (VPC, subnet pubbliche/private) dei lab precedenti.
- AWS Management Console o AWS CLI configurata con le credenziali del Learner Lab.
- Conoscenza base di Security Group e subnet pubbliche/private.
- Fallback previsto: se il Learner Lab non è raggiungibile o il costo/tempo di una VPN reale non è giustificato, documentare l'intera architettura (livelli, Security Group, collegamento ibrido) su schema Markdown, senza creare risorse reali.

## Scenario

- Il tuo gruppo deve dimostrare come un'applicazione multi-tier (web, application, database) sarebbe strutturata su AWS, con un ipotetico collegamento verso una rete on-premises.
- Devi posizionare i tre livelli su subnet distinte, con Security Group che permettono traffico solo dal livello immediatamente a monte.
- Devi creare (o documentare, se il costo non è giustificato) un Virtual Private Gateway e una VPN Connection dimostrativa verso un Customer Gateway simulato.

## Step

1. Documentare tre subnet di `demo-vpc`: web `10.0.1.0/24` pubblica, application `10.0.2.0/24` privata e database `10.0.3.0/24` privata dedicata. Per la terza, se si realizza la rete, usare **VPC → Subnets → Create subnet** dopo aver verificato che il CIDR sia libero; non associarle una rotta diretta verso IGW.
2. Individuare il Security Group del load balancer nella stessa VPC. Se il bilanciatore non esiste, creare `demo-sg-tier-alb` come gruppo pianificato per il livello di ingresso e annotare che non è associato a un ALB attivo. Non riusare automaticamente gruppi della VPC di default dei Lab 01–03.
3. In **EC2 → Security Groups → Create security group**, creare tutti i gruppi in `demo-vpc`: `demo-sg-tier-web` con inbound **HTTP/TCP 80** dal gruppo ALB; `demo-sg-tier-app` con **Custom TCP 8080** da `demo-sg-tier-web`; `demo-sg-tier-db` con **MySQL/Aurora TCP 3306** da `demo-sg-tier-app`. In ogni origine scegliere **Custom → ID del gruppo**, non un CIDR generico.
4. Verificare gli ID delle origini in **Inbound rules** e documentare la catena ALB → web → application → database. Il database non deve accettare direttamente il gruppo web.
5. Per il percorso VPN documentale, compilare i campi dei passaggi successivi senza creare risorse. Se si esegue la configurazione in console e i permessi lo consentono, aprire **VPC → Customer Gateways → Create customer gateway**, nome `demo-cgw`, BGP ASN `65000`, indirizzo pubblico del dispositivo di test. `203.0.113.10` è solo un indirizzo riservato agli esempi, non un endpoint operativo; se non accettato usare il percorso documentale.
6. In **Virtual Private Gateways → Create virtual private gateway**, creare `demo-vgw`, poi **Actions → Attach to VPC → demo-vpc**; verificare l'attachment.
7. In **Site-to-Site VPN Connections → Create VPN connection**, nome `demo-vpn`, **Target gateway type → Virtual private gateway → demo-vgw**, **Customer gateway → Existing → demo-cgw**, **Routing options → Static**, rete on-premises di esempio `192.168.0.0/16`. Creare e annotare lo stato della connessione e di entrambi i tunnel.
8. Senza apparato remoto i tunnel restano `DOWN`: questa prova documenta la configurazione lato AWS, non una connettività riuscita. Per un progetto operativo occorrono anche configurazione del dispositivo remoto e rotte nella VPC verso il gateway.
9. Motivare VPN o Direct Connect in base a banda, costo e tempi di attivazione; eseguire il cleanup delle risorse effettivamente create.

## Esempio di deliverable compilato

|    # | Elemento                  | Evidenza sintetica                                                      |
| ---: | ------------------------- | ----------------------------------------------------------------------- |
|    1 | SG livello web            | `demo-sg-tier-web`: HTTP (80) solo da SG del load balancer              |
|    2 | SG livello application    | `demo-sg-tier-app`: TCP 8080 solo da `demo-sg-tier-web`                 |
|    3 | SG livello database       | `demo-sg-tier-db`: 3306 solo da `demo-sg-tier-app`                      |
|    4 | VPN dimostrativa          | `demo-vpn` tra `demo-vgw` e `demo-cgw`, tunnel in stato `DOWN` (atteso) |
|    5 | Scelta VPN/Direct Connect | motivata su costo, banda e tempi di attivazione dello scenario          |

## Comandi eseguiti e output

Verifica delle regole a catena dei tre Security Group:

**Ubuntu (bash) / macOS (zsh/bash)**

```bash
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=demo-sg-tier-web,demo-sg-tier-app,demo-sg-tier-db" \
  --query "SecurityGroups[].{Name:GroupName,Rules:IpPermissions[].UserIdGroupPairs[].GroupId}"
```

**Windows PowerShell**

```powershell
aws ec2 describe-security-groups `
  --filters "Name=group-name,Values=demo-sg-tier-web,demo-sg-tier-app,demo-sg-tier-db" `
  --query "SecurityGroups[].{Name:GroupName,Rules:IpPermissions[].UserIdGroupPairs[].GroupId}"
```

Output atteso (illustrativo: gli ID dei Security Group variano a ogni creazione reale):

```
[
    {"Name": "demo-sg-tier-web", "Rules": ["sg-albdemo"]},
    {"Name": "demo-sg-tier-app", "Rules": ["sg-webdemo"]},
    {"Name": "demo-sg-tier-db",  "Rules": ["sg-appdemo"]}
]
```

Verifica dello stato della VPN Connection dimostrativa:

**Ubuntu (bash)**

```bash
aws ec2 describe-vpn-connections --filters "Name=tag:Name,Values=demo-vpn" \
  --query "VpnConnections[].{State:State,Tunnels:VgwTelemetry[].Status}"
```

**macOS (zsh/bash)**

```bash
aws ec2 describe-vpn-connections --filters "Name=tag:Name,Values=demo-vpn" \
  --query "VpnConnections[].{State:State,Tunnels:VgwTelemetry[].Status}"
```

**Windows PowerShell**

```powershell
aws ec2 describe-vpn-connections --filters "Name=tag:Name,Values=demo-vpn" `
  --query "VpnConnections[].{State:State,Tunnels:VgwTelemetry[].Status}"
```

Output atteso:

```
[
    {"State": "available", "Tunnels": ["DOWN", "DOWN"]}
]
```

Il fatto che ogni Security Group referenzi come origine il gruppo del livello a monte (non un CIDR) conferma la catena a minimo privilegio; lo stato `DOWN` dei tunnel VPN è il comportamento atteso e documentato, non un errore, in assenza di un dispositivo on-premises reale.

## Template operativo

```markdown
# Deliverable Lab 11

## Struttura multi-tier
| Livello | Subnet | Security Group | Origine consentita |
| Web | pubblica | demo-sg-tier-web | SG del load balancer |
| Application | privata | demo-sg-tier-app | demo-sg-tier-web |
| Database | privata dedicata | demo-sg-tier-db | demo-sg-tier-app |

## Collegamento ibrido dimostrativo
- Customer Gateway: demo-cgw
- Virtual Private Gateway: demo-vgw (collegato a demo-vpc)
- VPN Connection: demo-vpn (tunnel DOWN, atteso senza dispositivo reale)

## Scelta VPN vs Direct Connect
- Scenario assegnato: ...
- Scelta: ...
- Motivazione (costo, banda, tempi di attivazione): ...

## Cleanup
- VPN Connection, Customer Gateway, Virtual Private Gateway eliminati: si/no
- Regole di Security Group di test rimosse: si/no
```

## Esempio sintetico

- Decisione corretta: ogni Security Group referenzia il Security Group del livello immediatamente a monte, non un CIDR generico né un livello più lontano (es. il database non accetta mai traffico direttamente dal web).
- Evidenza minima: la catena di Security Group verificata via CLI/console, più lo stato (atteso `DOWN`) della VPN Connection documentato come comportamento normale in un ambiente didattico.
- Fallback accettabile: se il costo/tempo di una VPN reale non è giustificato, documentare l'intera architettura su schema Markdown senza creare risorse reali.
- Cleanup atteso: VPN Connection, Customer Gateway e Virtual Private Gateway eliminati; regole di Security Group di test rimosse.

## Checkpoint

- [x] Ogni livello accetta traffico solo dal Security Group del livello immediatamente a monte, non da `0.0.0.0/0` o da livelli più lontani
- [x] Virtual Private Gateway collegato correttamente alla VPC del progetto
- [x] Scelta tra VPN e Direct Connect motivata su costo, banda e tempi di attivazione dello scenario assegnato
- [x] Cleanup (VPN Connection, Customer Gateway, Virtual Private Gateway) eseguito o giustificato

## Errori comuni da evitare

- Permettere al livello web di raggiungere direttamente il database, saltando il livello application.
- Referenziare un CIDR generico invece del Security Group del livello a monte nelle regole a catena.
- Interpretare lo stato `DOWN` dei tunnel VPN come un errore da risolvere, invece che il comportamento atteso senza un dispositivo on-premises reale.
- Creare risorse VPN reali quando il costo/tempo non è giustificato dal lab, invece di usare il fallback documentale.

## Troubleshooting rapido

- Se la VPN Connection resta in stato `DOWN` o i tunnel non si stabiliscono, è atteso in un ambiente didattico senza un dispositivo on-premises reale: documenta comunque la configurazione lato AWS come evidenza.
- Se il Security Group del database blocca anche il traffico legittimo dal livello application, verifica di aver referenziato il Security Group corretto come origine, non un CIDR generico.
- Se il Virtual Private Gateway non risulta collegato alla VPC, verifica lo stato dell'attachment nella console VPC.
- Se il costo o il tempo stimato per una VPN reale non è giustificato dal lab, usa il fallback documentale invece di creare risorse che non verranno completate.

## Cleanup obbligatorio

- Elimina prima la VPN Connection e attendi il completamento; in **Virtual Private Gateways → Actions**, scollega `demo-vgw` dalla VPC e poi eliminalo. Elimina infine `demo-cgw`.
- Rimuovi eventuali regole di Security Group create solo per il test che non riflettono la configurazione finale documentata.
- Se non riusi i gruppi, elimina prima `demo-sg-tier-db`, poi `demo-sg-tier-app`, `demo-sg-tier-web` e l'eventuale gruppo ALB di sola progettazione; rimuovi prima associazioni e riferimenti che ne impediscono l'eliminazione. Elimina l'eventuale subnet database creata solo per il test.
- Verifica che non restino componenti VPN residui attivi nell'account del Learner Lab.
- Conferma nel deliverable che il cleanup è stato completato o indica cosa non è stato possibile rimuovere.
