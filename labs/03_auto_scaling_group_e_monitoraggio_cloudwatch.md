# Lab 03 - Auto Scaling Group e Monitoraggio con CloudWatch

## Obiettivo

- Focus operativo: configurare un Auto Scaling Group collegato al target group esistente, con un allarme CloudWatch sulla CPU, e verificare la sostituzione automatica di un'istanza terminata manualmente.
- Deliverable atteso: ASG funzionante con parametri di capacità documentati, allarme CloudWatch configurato, evidenza della sostituzione automatica.
- Nomi di risorsa usati in questa soluzione: launch template `demo-lt-web`, Auto Scaling Group `demo-asg-web`, scaling policy `demo-cpu-target`, allarme `demo-cpu-alta`.

## Prerequisiti

- Accesso attivo all'AWS Academy Learner Lab, con una AMI e un target group gia disponibili (es. dai Lab 01/02) oppure preparati al momento.
- AWS Management Console o AWS CLI configurata con le credenziali del Learner Lab.
- Conoscenza base di launch template, target group e metriche CloudWatch.
- Fallback previsto: se il Learner Lab non è raggiungibile, documentare parametri di scaling (minimo/desiderato/massimo) e soglia dell'allarme su scheda Markdown, senza creare risorse reali.

## Scenario

- Il tuo gruppo deve garantire che il servizio web resti disponibile anche in caso di guasto di una singola istanza, e che si adatti a un aumento di traffico.
- Devi creare un launch template dalla AMI disponibile, configurare un Auto Scaling Group con `minimo=1`, `desiderato=2`, `massimo=3`, collegato al target group del load balancer.
- Devi configurare il target tracking sulla CPU media del gruppo, un allarme manuale di osservazione su una singola istanza e verificare la sostituzione automatica di un'istanza terminata.

## Step

1. Verificare che `demo-web-ami-v1` sia `available`, contenga il web server abilitato all'avvio e che `demo-alb`/`demo-tg-web` esistano. Se rimossi, ricrearli seguendo il Lab 02.
2. In **EC2 → Launch Templates → Create launch template**, impostare `demo-lt-web`, descrizione `v1`, **My AMIs → Owned by me → demo-web-ami-v1**, `t3.micro`, key pair `demo-key` e Security Group `demo-sg-web` della stessa VPC.
3. In **Auto Scaling Groups → Create Auto Scaling group**, impostare `demo-asg-web` e selezionare `demo-lt-web`. In **Choose instance launch options**, scegliere la VPC e almeno due subnet nelle AZ abilitate sull'ALB.
4. In **Configure advanced options**, scegliere **Attach to an existing load balancer → Choose from your load balancer target groups → demo-tg-web** e attivare gli health check **Elastic Load Balancing**. Annotare il periodo di grazia per l'avvio del servizio.
5. In **Configure group size and scaling**, impostare capacità desiderata `2`, minima `1`, massima `3`. Attivare **Target tracking scaling policy**: nome `demo-cpu-target`, metrica **Average CPU utilization**, target `70`; controllare il riepilogo e creare il gruppo.
6. Attendere due istanze `InService` in **Instance management**, poi verificarle `healthy` nel target group. L'ASG lancia nuove istanze: quelle del Lab 02 già registrate nel target group non diventano automaticamente membri dell'ASG. Annotare gli ID delle istanze gestite; dopo la verifica deregistrare dal target group e fermare le due istanze originali se non servono al test.
7. In **CloudWatch → Alarms → All alarms → Create alarm → Select metric → EC2 → Per-Instance Metrics**, scegliere una delle istanze attive e `CPUUtilization`. Impostare **Average**, periodo **5 minutes**, soglia statica **Greater than 70**, 1 punto su 1; nome `demo-cpu-alta`. Omettere la notifica se non esiste un topic SNS oppure crearne uno e confermare l'email. Attendere dati e annotare lo stato.
8. Da EC2 terminare una delle istanze elencate in **Instance management**, senza ridurre la capacità desiderata dell'ASG. In **Auto Scaling Groups → demo-asg-web → Activity**, osservare l'avvio automatico della sostituta.
9. Verificare la nuova istanza `InService` e `healthy`, annotare ID e tempi osservati, poi eseguire il cleanup. Se l'allarme manuale osservava l'istanza terminata, aggiornarne la metrica a un ID attivo prima di verificarlo di nuovo.

La policy di target tracking gestisce propri allarmi per lo scaling. `demo-cpu-alta` è un allarme manuale su una singola istanza e non attiva automaticamente quella policy. Il collegamento al target group registra le istanze lanciate dall'ASG ([integrazione ALB/ASG](https://docs.aws.amazon.com/autoscaling/ec2/userguide/attach-load-balancer-asg.html)).

## Esempio di deliverable compilato

|    # | Elemento                | Evidenza sintetica                                                            |
| ---: | ----------------------- | ----------------------------------------------------------------------------- |
|    1 | Launch template         | `demo-lt-web`: AMI `demo-web-ami-v1`, `t3.micro`, key `demo-key`              |
|    2 | Auto Scaling Group      | `demo-asg-web`: minimo=1, desiderato=2, massimo=3, target group `demo-tg-web` |
|    3 | Scaling policy          | `demo-cpu-target`, target tracking CPU media 70%                              |
|    4 | Allarme CloudWatch      | `demo-cpu-alta`, `CPUUtilization`, media, periodo 5 min, soglia 70%           |
|    5 | Sostituzione automatica | istanza terminata sostituita (tempo osservato da annotare), nuova istanza `healthy`         |

## Comandi eseguiti e output

Verifica della cronologia di attività dell'ASG dopo la terminazione manuale:

**Ubuntu (bash) / macOS (zsh/bash)**

```bash
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name demo-asg-web --max-items 3
```

**Windows PowerShell**

```powershell
aws autoscaling describe-scaling-activities `
  --auto-scaling-group-name demo-asg-web --max-items 3
```

Output atteso (illustrativo: ID istanza e timestamp variano a ogni esecuzione reale):

```
{
    "Activities": [
        {
            "ActivityId": "a1b2c3d4-demo",
            "Description": "Launching a new EC2 instance: i-0newinstance",
            "StatusCode": "Successful",
            "Cause": "At 2026-07-21T10:15:00Z an instance was terminated in response to a difference between desired and actual capacity, shrinking the capacity from 2 to 1."
        }
    ]
}
```

Verifica dello stato dell'allarme CloudWatch:

**Ubuntu (bash) / macOS (zsh/bash)**

```bash
aws cloudwatch describe-alarms --alarm-names demo-cpu-alta \
  --query "MetricAlarms[].{Name:AlarmName,State:StateValue,Threshold:Threshold}"
```

**Windows PowerShell**

```powershell
aws cloudwatch describe-alarms --alarm-names demo-cpu-alta `
  --query "MetricAlarms[].{Name:AlarmName,State:StateValue,Threshold:Threshold}"
```

Output atteso:

```
[
    {"Name": "demo-cpu-alta", "State": "OK", "Threshold": 70.0}
]
```

Il campo `Cause` nell'attività dell'ASG conferma che la sostituzione è avvenuta automaticamente in risposta alla differenza tra capacità desiderata e reale, senza intervento manuale sull'ASG.

## Template operativo

```markdown
# Deliverable Lab 03

## Auto Scaling Group
- Nome: demo-asg-web
- Launch template: demo-lt-web (AMI demo-web-ami-v1, t3.micro)
- Capacità: minimo=1, desiderato=2, massimo=3
- Target group collegato: demo-tg-web

## Allarme CloudWatch
- Nome: demo-cpu-alta
- Metrica: CPUUtilization, media, periodo 5 min, soglia 70%
- Scaling policy: demo-cpu-target (target tracking)

## Evidenza sostituzione automatica
- Istanza terminata manualmente: i-...
- Nuova istanza lanciata da ASG: i-... (tempo osservato: ...)
- Stato nel target group: healthy

## Cleanup
- ASG eliminato: si/no
- Launch template eliminato: si/no
- Allarme eliminato: si/no
```

## Esempio sintetico

- Decisione corretta: `minimo=1` evita di ridurre deliberatamente il gruppo a zero in scale-in, mentre `minimo=0` lascerebbe il servizio temporaneamente senza istanze.
- Evidenza minima: l'evento di sostituzione automatica nella tab Activity dell'ASG, non solo la configurazione statica dei parametri.
- Fallback accettabile: se il Learner Lab non è raggiungibile, documentare i parametri di scaling e la soglia dell'allarme su scheda Markdown.
- Cleanup atteso: ASG eliminato (termina automaticamente le istanze gestite), launch template e allarme rimossi.

## Checkpoint

- [x] Parametri minimo/desiderato/massimo coerenti con un servizio sempre disponibile (minimo almeno 1)
- [x] Allarme CloudWatch con soglia e periodo di valutazione motivati
- [x] Terminare un'istanza gestita produce automaticamente una nuova istanza registrata e sana
- [x] Cleanup (ASG, launch template, allarme) eseguito o giustificato

## Errori comuni da evitare

- Impostare `minimo=0` per un servizio che deve restare sempre disponibile: rischia un'interruzione temporanea in scale-in.
- Dimenticare di attivare l'integrazione con gli health check dell'ELB, lasciando l'ASG a fidarsi solo dello status check EC2.
- Impostare una soglia dell'allarme troppo bassa: genera scaling continuo anche per carichi normali.
- Lasciare l'ASG attivo a fine lab: continua a mantenere istanze in esecuzione, consumando crediti del Learner Lab.

## Troubleshooting rapido

- Se l'ASG non lancia istanze, verifica che il launch template referenzi una AMI valida e un Security Group corretto.
- Se le nuove istanze risultano sempre `unhealthy`, controlla che il launch template usi lo stesso Security Group verificato nel Lab 02.
- Se l'allarme resta in stato `INSUFFICIENT_DATA`, verifica che il periodo di valutazione sia coerente con la frequenza delle metriche (5 minuti per il monitoraggio standard).
- Se la sostituzione dell'istanza terminata non avviene, verifica che il `desiderato` dell'ASG non sia stato modificato insieme alla terminazione manuale.

## Cleanup obbligatorio

- Elimina l'Auto Scaling Group (questo termina automaticamente le istanze gestite).
- Elimina il launch template creato per il test.
- Elimina l'allarme CloudWatch configurato per l'esercitazione.
- Al termine della sequenza 01–03, elimina anche ALB e target group, deregistra la AMI ed elimina i suoi snapshot se non servono più. Ferma le istanze originali se le riuserai per i lab di storage; altrimenti termina anche queste istanze. Rimuovi eventuali topic SNS creati solo per questa prova.
- Conferma nel deliverable che il cleanup è stato completato o indica cosa non è stato possibile rimuovere.