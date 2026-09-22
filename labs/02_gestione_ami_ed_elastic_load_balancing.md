# Lab 02 - Gestione Immagini AMI ed Elastic Load Balancing

## Obiettivo

- Focus operativo: creare una AMI riutilizzabile, lanciare una seconda istanza dalla stessa AMI e distribuire il traffico su entrambe con un Application Load Balancer che esclude automaticamente istanze non sane.
- Deliverable atteso: AMI documentata, ALB con target group e due istanze registrate, evidenza dello stato healthy/unhealthy prima e dopo un guasto simulato.
- Nomi di risorsa usati in questa soluzione (coerenti con il Demo 02 registrato): AMI `demo-web-ami-v1`, istanze `demo-web-01`/`demo-web-02`, load balancer `demo-alb`, target group `demo-tg-web`.

## Prerequisiti

- Accesso attivo all'AWS Academy Learner Lab, con un'istanza EC2 gia configurata (es. dal Lab 01) oppure una nuova istanza minimale da preparare.
- AWS Management Console o AWS CLI configurata con le credenziali del Learner Lab.
- Conoscenza base di Security Group e target group.
- Fallback previsto: se il Learner Lab non è raggiungibile, documentare i passaggi (creazione AMI, target group, listener) su scheda Markdown confrontandoli con la documentazione ufficiale, senza creare risorse reali.

## Scenario

- Il tuo gruppo ha un'istanza web funzionante e deve renderla riproducibile e resiliente a un guasto di singola istanza.
- Devi creare una AMI dall'istanza esistente, lanciare una seconda istanza dalla stessa AMI in una subnet diversa, e mettere entrambe dietro un Application Load Balancer.
- Il load balancer deve escludere automaticamente un'istanza che smette di rispondere, senza intervento manuale.

## Step

1. Fermare l'istanza sorgente `demo-web-01` (dal Lab 01) per garantire uno stato coerente al momento dello snapshot.
2. Creare una AMI **demo-web-ami-v1** da `demo-web-01`, attendere lo stato `available` (richiede alcuni minuti per gli snapshot EBS sottostanti).
3. Riavviare `demo-web-01`, poi lanciare `demo-web-02` dalla stessa AMI in una subnet diversa (altra Availability Zone), riusando key pair e Security Group.
4. Creare un target group `demo-tg-web` (HTTP, porta 80, health check su `/`) e registrare entrambe le istanze.
5. Creare l'Application Load Balancer `demo-alb` (internet-facing, listener HTTP:80 verso `demo-tg-web`), con Security Group che permette traffico in ingresso sulla porta 80.
6. Verificare che entrambe le istanze risultino `healthy` nel target group.
7. Fermare `demo-web-02` e osservare che il target group la escluda entro pochi controlli di health check; riavviarla e verificare il ritorno a `healthy`.

## Esempio di deliverable compilato

|    # | Elemento              | Evidenza sintetica                                                           |
| ---: | --------------------- | ---------------------------------------------------------------------------- |
|    1 | AMI                   | `demo-web-ami-v1`, creata da `demo-web-01` fermata, stato `available`        |
|    2 | Seconda istanza       | `demo-web-02`, lanciata dalla stessa AMI, subnet diversa                     |
|    3 | Target group          | `demo-tg-web`, HTTP:80, health check su `/`                                  |
|    4 | Load balancer         | `demo-alb`, internet-facing, listener HTTP:80 → `demo-tg-web`                |
|    5 | Verifica health check | entrambe `healthy`; dopo stop di `demo-web-02`, solo `demo-web-01` `healthy` |

## Comandi eseguiti e output

Verifica dello stato della AMI prima di lanciare la seconda istanza:

**Ubuntu (bash) / macOS (zsh/bash)**

```bash
aws ec2 describe-images --owners self \
  --filters "Name=name,Values=demo-web-ami-v1" \
  --query "Images[].{Name:Name,State:State,ImageId:ImageId}" --output table
```

**Windows PowerShell**

```powershell
aws ec2 describe-images --owners self `
  --filters "Name=name,Values=demo-web-ami-v1" `
  --query "Images[].{Name:Name,State:State,ImageId:ImageId}" --output table
```

Output atteso (illustrativo: l'ID immagine varia a ogni creazione reale):

```
---------------------------------------------------
|                 DescribeImages                   |
+------------------+-----------+--------------------+
|     ImageId      |   Name    |       State        |
+------------------+-----------+--------------------+
|  ami-0abc123demo |  demo-web-ami-v1 |  available   |
+------------------+-----------+--------------------+
```

Verifica dello stato di salute del target group, prima e dopo aver fermato `demo-web-02`:

**Ubuntu (bash) / macOS (zsh/bash) / Windows PowerShell**

```bash
aws elbv2 describe-target-health --target-group-arn <arn-demo-tg-web>
```

Output atteso **prima** dello stop:

```
{
    "TargetHealthDescriptions": [
        {"Target": {"Id": "i-demoweb01", "Port": 80}, "TargetHealth": {"State": "healthy"}},
        {"Target": {"Id": "i-demoweb02", "Port": 80}, "TargetHealth": {"State": "healthy"}}
    ]
}
```

Output atteso **dopo** lo stop di `demo-web-02` (entro pochi controlli di health check):

```
{
    "TargetHealthDescriptions": [
        {"Target": {"Id": "i-demoweb01", "Port": 80}, "TargetHealth": {"State": "healthy"}},
        {"Target": {"Id": "i-demoweb02", "Port": 80}, "TargetHealth": {"State": "unhealthy", "Reason": "Target.Timeout"}}
    ]
}
```

Il campo `TargetHealth.State` conferma che il load balancer ha rilevato automaticamente l'istanza guasta, senza intervento manuale sul target group o sull'ALB.

## Template operativo

```markdown
# Deliverable Lab 02

## AMI
- Nome: demo-web-ami-v1
- Creata da: demo-web-01 (fermata prima della creazione)
- Stato: available

## Load balancer
- Nome: demo-alb
- Target group: demo-tg-web (HTTP:80, health check su /)
- Istanze registrate: demo-web-01, demo-web-02

## Evidenza health check
- Prima dello stop: entrambe healthy
- Dopo lo stop di demo-web-02: demo-web-01 healthy, demo-web-02 unhealthy
- Dopo il riavvio: entrambe healthy

## Cleanup
- ALB e target group eliminati: si/no
- AMI deregistrata e snapshot eliminati: si/no
```

## Esempio sintetico

- Decisione corretta: fermare l'istanza sorgente prima di creare la AMI, per evitare di catturare uno stato incoerente dei volumi EBS collegati.
- Evidenza minima: stato `healthy`/`unhealthy` del target group osservato prima e dopo il guasto simulato, non solo la configurazione statica.
- Fallback accettabile: se il Learner Lab non è raggiungibile, documentare i passaggi (AMI, target group, listener) su scheda Markdown senza creare risorse reali.
- Cleanup atteso: ALB e target group eliminati, entrambe le istanze terminate, AMI deregistrata e snapshot rimossi.

## Checkpoint

- [x] AMI creata da un'istanza in stato coerente, con nome che ne indica versione e contenuto
- [x] Target group mostra correttamente lo stato di salute delle istanze registrate
- [x] Fermare un'istanza produce l'esclusione automatica dal bilanciamento, senza intervento manuale
- [x] Cleanup completo (ALB, target group, istanze, AMI, snapshot) eseguito o giustificato

## Errori comuni da evitare

- Creare la AMI da un'istanza ancora in scrittura attiva: rischia di catturare uno stato incoerente dei volumi.
- Dimenticare di verificare che la AMI sia `available` prima di lanciare la seconda istanza.
- Registrare un'istanza nel target group senza aprire la porta corretta nel suo Security Group: risulta sempre `unhealthy`.
- Deregistrare la AMI senza eliminare gli snapshot EBS collegati, lasciando costi di storage residui.

## Troubleshooting rapido

- Se la creazione della AMI resta a lungo in stato `pending`, verifica lo stato degli snapshot EBS associati prima di considerarla bloccata.
- Se un'istanza risulta sempre `unhealthy`, controlla che il suo Security Group permetta il traffico dal load balancer sulla porta dell'health check.
- Se il load balancer non risponde, verifica che il suo Security Group accetti traffico in ingresso sulla porta del listener (80).
- Se la seconda istanza non trova la AMI, verifica che la AMI sia nello stato `available` e nella stessa regione.

## Cleanup obbligatorio

- Elimina il load balancer e il target group creati per l'esercitazione.
- Termina entrambe le istanze EC2 usate nel lab.
- Deregistra la AMI di test (`deregister-image`) ed elimina gli snapshot EBS collegati, se non piu necessari.
- Conferma nel deliverable che il cleanup è stato completato o indica cosa non è stato possibile rimuovere.
