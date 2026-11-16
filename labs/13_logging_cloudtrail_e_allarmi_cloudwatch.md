# Lab 13 - Logging con CloudTrail e Allarmi CloudWatch

## Obiettivo

- Focus operativo: configurare un trail CloudTrail persistente, individuare un evento di audit specifico, e collegare allarmi CloudWatch su CPU e storage a un topic SNS funzionante.
- Deliverable atteso: trail attivo con log su bucket dedicato, evento di audit documentato, due allarmi CloudWatch collegati a notifica reale.
- Nomi di risorsa usati in questa soluzione: trail `demo-trail`, topic SNS `demo-topic-alarm`, allarme storage `demo-alarm-ebs-queue` e allarme CPU `demo-cpu-alta`, entrambi con notifica SNS.

## Prerequisiti

- Accesso attivo all'AWS Academy Learner Lab, con un'istanza EC2 e un volume EBS dai lab precedenti.
- AWS Management Console o AWS CLI configurata con le credenziali del Learner Lab.
- Conoscenza base di CloudWatch (dalla Lezione 03) e concetti di audit.
- Regione operativa `us-east-1` oppure `us-west-2`. Usare risorse proprie con prefisso `demo-` e lasciare invariati i componenti di sistema e monitoring Academy.
- Fallback previsto: se il Learner Lab non è raggiungibile, documentare la configurazione di trail e allarmi pianificata su tabella Markdown, senza creare risorse reali.

## Scenario

- Il tuo gruppo, dopo la verifica intermedia, deve dimostrare capacità di audit e monitoraggio proattivo su VM e storage.
- Devi creare un trail CloudTrail persistente che scriva su un bucket S3 dedicato, e verificare la presenza di eventi recenti.
- Devi configurare allarmi CloudWatch su CPU e su un volume EBS, entrambi collegati a un topic SNS che invii effettivamente una notifica.

## Step

1. Aprire **CloudTrail → Trails → Create trail**, nome `demo-trail`. In **Storage location**, scegliere **Create new S3 bucket**, nome univoco `demo-cloudtrail-logs-<iniziali>`. Il wizard configura i permessi di scrittura del servizio sul bucket; per un bucket preesistente verificare la bucket policy richiesta da CloudTrail.
2. Selezionare gli eventi **Management events**, lettura e scrittura, e mantenere la validazione dei log. Per questa esercitazione disattivare **Log file SSE-KMS encryption** nel wizard e verificare che il bucket nuovo usi la cifratura predefinita **SSE-S3**. Lasciare disattivata l'integrazione **CloudWatch Logs**: gli allarmi del lab usano metriche EC2/EBS e SNS, senza richiedere un nuovo ruolo IAM. Non abilitare eventi dati, Insights o trail di organizzazione. Creare il trail e verificare **Logging = On**; se fermo usare **Start logging** o `aws cloudtrail start-logging --name demo-trail`. La console crea un trail multi-regione; la verifica degli eventi di test si svolge nella regione operativa scelta.
3. In **EC2 → Volumes → Create volume**, creare un volume `gp3` da 1 GiB nella regione del lab. Annotare ID e ora, attendere `available`, quindi eliminarlo: genera gli eventi `CreateVolume` e `DeleteVolume`.
4. In **CloudTrail → Event history**, filtrare **Event name → CreateVolume**, individuare l'evento corrispondente all'ID annotato e aprire **Event record**. Annotare azione, identità, timestamp e presenza/assenza di errori.
5. Controllare anche il bucket del trail: attendere i file sotto `AWSLogs/<account-id>/CloudTrail/<regione>/...` e verificare la consegna dei log. La sola Event History non prova che il trail stia scrivendo su S3.
6. In **SNS → Topics → Create topic**, scegliere **Standard**, nome `demo-topic-alarm`. Aprire **Create subscription**, protocollo **Email**, indirizzo proprio; confermare dal link ricevuto e verificare che non sia più `Pending confirmation`.
7. In **CloudWatch → Alarms → Create alarm → Select metric → EBS → Per-Volume Metrics**, scegliere un volume ancora collegato a un'istanza attiva (non quello eliminato al punto 3), metrica `VolumeQueueLength`, **Average**, periodo **5 minutes**, soglia **Greater than 5**, 1 punto su 1. In **Notification → In alarm**, scegliere `demo-topic-alarm`; nome `demo-alarm-ebs-queue`.
8. Creare analogamente `demo-cpu-alta` su **EC2 → Per-Instance Metrics → CPUUtilization** dell'istanza attiva, **Average**, **5 minutes**, soglia **Greater than 70**, 1 punto su 1, notifica allo stesso topic. Se l'allarme omonimo esiste ed è un allarme manuale proprio del Lab 03, aggiornare ID istanza e notifica; se appartiene ad altre attività, usare un nome distinto come `demo-cpu-alta-lab13` e adattare i comandi. Non modificare gli allarmi gestiti dal target tracking o dal monitoring Academy; questi due allarmi di test devono avere solo azioni SNS.
9. Attendere metriche valide e annotare lo stato di entrambi. Eseguire il test di notifica sotto, verificando l'email e la cronologia allarmi; distinguere il test simulato da un superamento reale della soglia.
10. Documentare evento, file consegnato su S3, parametri degli allarmi e notifica ricevuta, poi eseguire il cleanup.

## Esempio di deliverable compilato

|    # | Elemento         | Evidenza sintetica                                                          |
| ---: | ---------------- | --------------------------------------------------------------------------- |
|    1 | Trail CloudTrail | `demo-trail`, `IsLogging: true`, log su bucket dedicato                     |
|    2 | Evento di audit  | `CreateVolume`/`DeleteVolume`, utente e timestamp annotati                  |
|    3 | Topic SNS        | `demo-topic-alarm`, sottoscrizione email confermata                         |
|    4 | Allarme storage  | `demo-alarm-ebs-queue`, `VolumeQueueLength`, collegato a `demo-topic-alarm` |
|    5 | Allarme CPU      | `demo-cpu-alta` (riuso pattern Lab 03), collegato a `demo-topic-alarm`      |

## Comandi eseguiti e output

Verifica dello stato del trail e dell'evento di audit:

**Ubuntu (bash) / macOS (zsh/bash)**

```bash
aws cloudtrail get-trail-status --name demo-trail --query "{IsLogging:IsLogging}"

aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=CreateVolume \
  --max-results 1 --query "Events[].{User:Username,Time:EventTime,Name:EventName}"
```

**Windows PowerShell**

```powershell
aws cloudtrail get-trail-status --name demo-trail --query "{IsLogging:IsLogging}"

aws cloudtrail lookup-events `
  --lookup-attributes AttributeKey=EventName,AttributeValue=CreateVolume `
  --max-results 1 --query "Events[].{User:Username,Time:EventTime,Name:EventName}"
```

Output atteso (illustrativo: utente e timestamp variano a ogni esecuzione reale):

```
{"IsLogging": true}
[{"User": "voclabs", "Time": "2026-07-21T10:05:00+00:00", "Name": "CreateVolume"}]
```

Verifica dello stato di entrambi gli allarmi CloudWatch e delle relative azioni di notifica:

**Ubuntu (bash) / macOS (zsh/bash)**

```bash
aws cloudwatch describe-alarms --alarm-names demo-alarm-ebs-queue demo-cpu-alta \
  --query "MetricAlarms[].{Name:AlarmName,State:StateValue,Actions:AlarmActions}"
```

**Windows PowerShell**

```powershell
aws cloudwatch describe-alarms --alarm-names demo-alarm-ebs-queue demo-cpu-alta `
  --query "MetricAlarms[].{Name:AlarmName,State:StateValue,Actions:AlarmActions}"
```

Output atteso:

```
[
    {"Name": "demo-alarm-ebs-queue", "State": "OK", "Actions": ["arn:aws:sns:us-east-1:123456789012:demo-topic-alarm"]},
    {"Name": "demo-cpu-alta", "State": "OK", "Actions": ["arn:aws:sns:us-east-1:123456789012:demo-topic-alarm"]}
]
```

Il campo `Actions` conferma la destinazione configurata; la sottoscrizione confermata e il test con ricezione email verificano il recapito effettivo.

### Verifica della notifica degli allarmi

Dal terminale con AWS CLI e credenziali del Learner Lab, controllare prima che i due allarmi creati per il lab abbiano **azioni abilitate e solo SNS**, senza azioni EC2 o Auto Scaling. Per ciascun allarme, impostare temporaneamente lo stato `OK` e poi `ALARM`; esempio per lo storage (comandi validi anche in PowerShell):

```bash
aws cloudwatch set-alarm-state --alarm-name demo-alarm-ebs-queue --state-value OK --state-reason "Preparazione test didattico"
aws cloudwatch set-alarm-state --alarm-name demo-alarm-ebs-queue --state-value ALARM --state-reason "Test didattico notifica SNS"
```

Ripetere sostituendo il nome con `demo-cpu-alta`. Verificare **History** di ogni allarme e l'email ricevuta, annotando che lo stato è stato simulato. CloudWatch rivaluta successivamente la metrica e ripristina lo stato corrispondente ai dati ([SetAlarmState](https://docs.aws.amazon.com/AmazonCloudWatch/latest/APIReference/API_SetAlarmState.html)). Se il comando è negato, documentare il limite senza dichiarare una consegna non verificata.

## Template operativo

```markdown
# Deliverable Lab 13

## Trail CloudTrail
- Nome: demo-trail
- Bucket log: demo-cloudtrail-logs-<iniziali>
- IsLogging: true

## Evento di audit individuato
- Azione: CreateVolume (o altra azione generata)
- Utente: voclabs
- Timestamp: ...
- Esito: Success

## Allarmi CloudWatch
- demo-alarm-ebs-queue: VolumeQueueLength, collegato a demo-topic-alarm
- demo-cpu-alta: CPUUtilization, collegato a demo-topic-alarm

## Topic SNS
- Nome: demo-topic-alarm
- Sottoscrizione confermata: si
- Email di test ricevuta per ciascun allarme: si/no
- Test di stato simulato, non superamento reale della soglia: si

## Cleanup
- Trail fermato ed eliminato: si/no
- Bucket log svuotato ed eliminato: si/no
- Allarmi e topic SNS eliminati: si/no
```

## Esempio sintetico

- Decisione corretta: collegare entrambi gli allarmi (CPU e storage) allo stesso topic SNS con notifica reale, non lasciarne uno senza destinazione.
- Evidenza minima: l'evento di audit specifico trovato in CloudTrail (non solo "il trail esiste"), più la consegna dei log su S3 e le email ricevute durante il test di entrambi gli allarmi.
- Fallback accettabile: se il Learner Lab non è raggiungibile, documentare la configurazione di trail e allarmi pianificata su tabella Markdown.
- Cleanup atteso: trail fermato ed eliminato, bucket dei log svuotato ed eliminato, allarmi e topic SNS rimossi.

## Checkpoint

- [x] Trail CloudTrail attivo (`IsLogging: true`) che scrive effettivamente sul bucket dedicato
- [x] Evento di audit documentato con azione, utente, timestamp ed esito
- [x] Entrambi gli allarmi CloudWatch collegati a una destinazione di notifica reale (topic SNS)
- [x] Cleanup (trail, bucket log, allarmi, topic SNS) eseguito o giustificato

## Errori comuni da evitare

- Lasciare attive opzioni del wizard che richiedono una nuova chiave KMS o la creazione di un ruolo per CloudWatch Logs, senza averne verificato i prerequisiti. Il percorso base usa S3 con SSE-S3 e metriche EC2/EBS con SNS ([configurazione del trail](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-create-a-trail-using-the-console-first-time.html)).
- Confondere gli allarmi gestiti dal target tracking dell'ASG con l'allarme CPU manuale: qui entrambi gli allarmi devono avere la notifica SNS configurata.
- Considerare il trail "attivo" solo perché creato, senza verificare esplicitamente `IsLogging: true` e la presenza di log nel bucket.
- Non confermare la sottoscrizione SNS via email, lasciando la notifica non funzionante nonostante l'allarme sia configurato.
- Dimenticare che il bucket dei log di CloudTrail va svuotato prima di poter essere eliminato.

## Troubleshooting rapido

- Se il trail non mostra eventi, attendi qualche minuto: la scrittura dei log su S3 non è istantanea.
- Se la sottoscrizione SNS resta in stato "non confermata", verifica di aver confermato l'iscrizione tramite il link ricevuto via email.
- Se un allarme non scatta come previsto, verifica che periodo ed evaluation-periods siano coerenti con l'intervallo di raccolta della metrica.
- Se non trovi l'evento generato in Event History, filtra per nome risorsa o intervallo di tempo più ampio prima di considerarlo assente.

## Cleanup obbligatorio

- Ferma (`stop-logging`) ed elimina il trail CloudTrail creato per il test.
- Svuota ed elimina il bucket S3 dedicato ai log di CloudTrail.
- Elimina gli allarmi CloudWatch e il topic SNS creati per l'esercitazione.
- Conferma nel deliverable che il cleanup è stato completato o indica cosa non è stato possibile rimuovere.
