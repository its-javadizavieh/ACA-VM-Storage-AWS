# Lab 02 - Gestione Immagini AMI ed Elastic Load Balancing

## Obiettivo

- Focus operativo: creare una AMI riutilizzabile, lanciare una seconda istanza dalla stessa AMI e distribuire il traffico su entrambe con un Application Load Balancer che esclude automaticamente istanze non sane.
- Deliverable atteso: AMI documentata, ALB con target group e due istanze registrate, evidenza dello stato dei target prima e dopo un guasto simulato.
- Nomi di risorsa usati in questa soluzione: AMI `demo-web-ami-v1`, istanze `demo-web-01`/`demo-web-02`, load balancer `demo-alb`, target group `demo-tg-web`.

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

1. Avviare `demo-web-01` del Lab 01, collegarsi in SSH e preparare il web server con i comandi sotto. Verificare una risposta HTTP 200 su `/` prima di creare la AMI; la sola apertura della porta 80 non installa il servizio.
2. In **EC2 → Instances**, selezionare `demo-web-01`, **Instance state → Stop instance** e attendere `stopped`. Aprire **Actions → Image and templates → Create image**, nome `demo-web-ami-v1`, descrizione della configurazione e volumi invariati; scegliere **Create image**.
3. In **Images → AMIs**, attendere `available` e annotare AMI ID e snapshot associati. Riavviare `demo-web-01` con **Start instance**.
4. Selezionare la AMI → **Launch instance from AMI**: nome `demo-web-02`, `t3.micro`, key pair `demo-key`, stessa VPC, subnet pubblica in un'altra AZ, IP pubblico abilitato, gruppo esistente `demo-sg-web`. Attendere gli status check e verificare il web server anche sulla seconda istanza.
5. In **Target Groups → Create target group**, scegliere **Instances**, nome `demo-tg-web`, **HTTP:80**, stessa VPC e health check path `/`. Con **Next**, selezionare entrambe le istanze → **Include as pending below → Create target group**.
6. In **Load Balancers → Create load balancer → Application Load Balancer**, impostare `demo-alb`, **Internet-facing**, stessa VPC e due subnet pubbliche in AZ diverse. Associare `demo-sg-web` e configurare il listener **HTTP:80 → Forward to demo-tg-web**; creare il bilanciatore.
7. Attendere lo stato ALB `active`; in **Target Groups → demo-tg-web → Targets**, verificare entrambe le istanze `healthy`. Se necessario controllare il servizio HTTP e la porta 80 dal bilanciatore alle istanze.
8. Copiare il **DNS name** dell'ALB e aprire `http://<DNS-ALB>/` nel browser. Annotare la risposta e verificare che il servizio resti raggiungibile durante la prova successiva.
9. Fermare `demo-web-02` da EC2, osservare lo stato del target e verificare che l'ALB continui a servire richieste tramite `demo-web-01`. Un'istanza fermata può risultare `unused` con motivo `Target.InvalidState`; un servizio HTTP guasto su un'istanza attiva può risultare `unhealthy`. Riavviare l'istanza e attendere il ritorno a `healthy`.
10. Documentare gli stati realmente osservati. Se si prosegue subito con il Lab 03, conservare AMI, snapshot, ALB e target group; altrimenti eseguire il cleanup completo.

### Preparare il web server prima della AMI

Eseguire nella sessione SSH su **Amazon Linux 2023**, anche se il terminale locale è PowerShell:

```bash
sudo dnf install -y httpd
echo 'Servizio web del laboratorio AWS' | sudo tee /var/www/html/index.html
sudo systemctl enable --now httpd
curl -I http://localhost/
```

La risposta deve essere HTTP 200. `enable` permette al servizio di ripartire anche sulle istanze create dalla AMI. Procedura di riferimento: [web server su Amazon Linux 2023](https://docs.aws.amazon.com/linux/al2023/ug/ec2-lamp-amazon-linux-2023.html).

Per distinguere i due backend, dopo il lancio eseguire `hostname | sudo tee /var/www/html/index.html` su ciascuna istanza. Ricaricare la pagina dell'ALB senza assumere un'alternanza fissa a ogni richiesta.

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
        {"Target": {"Id": "i-demoweb02", "Port": 80}, "TargetHealth": {"State": "unused", "Reason": "Target.InvalidState"}}
    ]
}
```

Lo stato illustrato è coerente con un target fermato ([stati dei target ALB](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/check-target-health.html)). Il campo `TargetHealth.State` conferma che il load balancer ha rilevato automaticamente l'istanza guasta, senza intervento manuale sul target group o sull'ALB.

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
- Dopo lo stop di demo-web-02: demo-web-01 healthy, demo-web-02 unused (Target.InvalidState)
- Dopo il riavvio: entrambe healthy

## Cleanup
- ALB e target group eliminati: si/no
- AMI deregistrata e snapshot eliminati: si/no
```

## Esempio sintetico

- Decisione corretta: fermare l'istanza sorgente prima di creare la AMI, per evitare di catturare uno stato incoerente dei volumi EBS collegati.
- Evidenza minima: stato dei target (`healthy` prima, escluso dopo lo stop) osservato prima e dopo il guasto simulato, non solo la configurazione statica.
- Fallback accettabile: se il Learner Lab non è raggiungibile, documentare i passaggi (AMI, target group, listener) su scheda Markdown senza creare risorse reali.
- Cleanup atteso: completo se il percorso termina qui; se si prosegue subito con il Lab 03, documentare le risorse mantenute e verificarne il consumo di crediti.

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

Se si prosegue subito con il Lab 03, conservare AMI, snapshot, ALB e target group e documentare il riuso. Le istanze originali possono essere fermate tra le sessioni. Al termine del percorso, applicare i passaggi seguenti.

- Elimina il load balancer e il target group creati per l'esercitazione.
- Termina entrambe le istanze EC2 usate nel lab.
- Deregistra la AMI di test (`deregister-image`) ed elimina gli snapshot EBS collegati, se non piu necessari.
- Conferma nel deliverable che il cleanup è stato completato o indica cosa non è stato possibile rimuovere.
