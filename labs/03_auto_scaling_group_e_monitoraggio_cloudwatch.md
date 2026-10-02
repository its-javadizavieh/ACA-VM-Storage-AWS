# Lab 03 - Auto Scaling Group e Monitoraggio con CloudWatch

## Obiettivo

- Focus operativo: configurare un Auto Scaling Group collegato al target group esistente, con un allarme CloudWatch sulla CPU, e verificare la sostituzione automatica di un'istanza terminata manualmente.
- Deliverable atteso: ASG funzionante con parametri di capacità documentati, allarme CloudWatch configurato, evidenza della sostituzione automatica.
- Nomi di risorsa usati in questa soluzione (coerenti con il Demo 03 registrato): launch template `demo-lt-web`, Auto Scaling Group `demo-asg-web`, scaling policy `demo-cpu-target`, allarme `demo-cpu-alta`.

## Prerequisiti

- Accesso attivo all'AWS Academy Learner Lab, con una AMI e un target group gia disponibili (es. dai Lab 01/02) oppure preparati al momento.
- AWS Management Console o AWS CLI configurata con le credenziali del Learner Lab.
- Conoscenza base di launch template, target group e metriche CloudWatch.
- Fallback previsto: se il Learner Lab non è raggiungibile, documentare parametri di scaling (minimo/desiderato/massimo) e soglia dell'allarme su scheda Markdown, senza creare risorse reali.

## Scenario

- Il tuo gruppo deve garantire che il servizio web resti disponibile anche in caso di guasto di una singola istanza, e che si adatti a un aumento di traffico.
- Devi creare un launch template dalla AMI disponibile, configurare un Auto Scaling Group con `minimo=1`, `desiderato=2`, `massimo=3`, collegato al target group del load balancer.
- Devi impostare un allarme CloudWatch sulla CPU media che attiva lo scale-out, e verificare che l'ASG sostituisca automaticamente un'istanza terminata manualmente.

## Step

1. Creare il launch template **demo-lt-web**, referenziando la AMI `demo-web-ami-v1` (dal Lab 02), tipo istanza `t3.micro`, key pair `demo-key` e Security Group `demo-sg-web`.
2. Creare l'Auto Scaling Group **demo-asg-web** basato su `demo-lt-web`, con `minimo=1`, `desiderato=2`, `massimo=3`, distribuito su almeno due subnet/Availability Zone e collegato al target group `demo-tg-web`.
3. Attivare l'integrazione con gli health check dell'ELB, così l'ASG usa anche lo stato del target group, non solo lo status check EC2.
4. Attendere che l'ASG raggiunga la capacità desiderata (2 istanze) e verificare che risultino `healthy` nel target group.
5. Configurare la scaling policy **demo-cpu-target** (target tracking, CPU media al 70%).
6. Creare l'allarme CloudWatch **demo-cpu-alta** sulla metrica `CPUUtilization` (media, periodo 5 minuti, soglia 70%).
7. Terminare manualmente una delle istanze gestite e osservare, nella tab **Activity** dell'ASG, l'evento di sostituzione automatica.
8. Verificare che la nuova istanza venga registrata nel target group e risulti `healthy`, poi documentare ed eseguire il cleanup.

## Esempio di deliverable compilato

|    # | Elemento                | Evidenza sintetica                                                            |
| ---: | ----------------------- | ----------------------------------------------------------------------------- |
|    1 | Launch template         | `demo-lt-web`: AMI `demo-web-ami-v1`, `t3.micro`, key `demo-key`              |
|    2 | Auto Scaling Group      | `demo-asg-web`: minimo=1, desiderato=2, massimo=3, target group `demo-tg-web` |
|    3 | Scaling policy          | `demo-cpu-target`, target tracking CPU media 70%                              |
|    4 | Allarme CloudWatch      | `demo-cpu-alta`, `CPUUtilization`, media, periodo 5 min, soglia 70%           |
|    5 | Sostituzione automatica | istanza terminata sostituita entro ~3 minuti, nuova istanza `healthy`         |

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
- Nuova istanza lanciata da ASG: i-... (entro ~3 minuti)
- Stato nel target group: healthy

## Cleanup
- ASG eliminato: si/no
- Launch template eliminato: si/no
- Allarme eliminato: si/no
```

## Esempio sintetico

- Decisione corretta: `minimo=1` garantisce continuità di servizio anche in scale-in, mentre `minimo=0` lascerebbe il servizio temporaneamente senza istanze.
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
- Conferma nel deliverable che il cleanup è stato completato o indica cosa non è stato possibile rimuovere.