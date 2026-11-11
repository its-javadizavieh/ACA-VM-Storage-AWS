# Lab 12 - Bilanciamento Rete/Storage, Best Practice di Resilienza e IAM Roles/Policy

## Obiettivo

- Focus operativo: diagnosticare se il collo di bottiglia di un'istanza è di rete o di storage, verificare snapshot/versioning esistenti, e progettare e simulare una policy IAM a minimo privilegio senza creare ruoli o modificare `LabRole`.
- Deliverable atteso: analisi rete/storage basata su metriche osservate, conferma di snapshot/versioning attivi, policy JSON minima con risultati della simulazione documentati.
- File da preparare: `lab12-s3-readonly.json`, con soli `s3:GetObject` e `s3:ListBucket` sul bucket scelto.

## Prerequisiti

- Accesso attivo all'AWS Academy Learner Lab, con almeno un'istanza EC2 e un bucket S3 dai lab precedenti.
- AWS Management Console o AWS CLI configurata con le credenziali del Learner Lab.
- Conoscenza base di CloudWatch, snapshot EBS, versioning S3 e concetti IAM.
- Fallback previsto: se il Learner Lab non è raggiungibile, documentare l'analisi delle metriche e la policy IAM pianificata su tabella Markdown, senza creare risorse reali.

## Scenario

- Il tuo gruppo deve dimostrare di saper diagnosticare un collo di bottiglia, verificare che le pratiche di resilienza siano effettivamente in atto, e gestire un accesso IAM a minimo privilegio.
- Devi analizzare le metriche CloudWatch di un'istanza esistente per capire se il limite prevalente è di rete o di storage.
- Devi scrivere una policy minima di sola lettura su un bucket S3 e verificarne il comportamento con il simulatore, senza allegarla a un ruolo o cambiare le autorizzazioni dell'ambiente.

## Uso di IAM nell'esercitazione

La parte IAM consiste nello scrivere una policy JSON e simularne le decisioni. Non occorre creare un ruolo, allegare policy o modificare l'instance profile dell'istanza. `LabRole` e `LabInstanceProfile` sono già predisposti dall'Academy e vanno lasciati invariati.

## Step

1. Preparare un'istanza Linux attiva con volume EBS collegato, uno snapshot recente e il bucket con versioning dei Lab 07/08. Ricrearli con quei lab se già eliminati.
2. Aprire **CloudWatch → All metrics → EC2 → Per-Instance Metrics** e scegliere l'ID dell'istanza, `CPUUtilization`, `NetworkIn` e `NetworkOut`. Aggiungere da **EBS → Per-Volume Metrics** il volume collegato e `VolumeReadOps`, `VolumeWriteOps`, `VolumeQueueLength`; usare lo stesso intervallo temporale e periodo.
3. Confrontare i grafici in **Graphed metrics**. Documentare unità, statistiche e tempi: molte operazioni non provano da sole saturazione. Cercare code persistenti e confrontare IOPS/throughput con la configurazione del volume; se il carico è insufficiente, dichiarare che non emerge un collo di bottiglia.
4. In **EC2 → Snapshots**, verificare ID volume, data e stato `completed`; in **S3 → bucket → Properties**, verificare **Bucket Versioning → Enabled**.
5. Sul computer locale, creare con un editor il file **`lab12-s3-readonly.json`**, incollare la policy sotto e sostituire `NOME_BUCKET_REALE` in entrambi gli ARN. Non usare **Create role**, non allegare la policy a `LabRole` e non modificare l'instance profile della EC2.
6. Dal terminale locale con AWS CLI e credenziali temporanee Academy valide, verificare l'identità con `aws sts get-caller-identity`. Aprire il terminale nella cartella del JSON ed eseguire i comandi di simulazione sotto: `ListBucket` e `GetObject` sul bucket scelto devono risultare `allowed`; `PutObject` e `GetObject` su un altro bucket devono risultare `implicitDeny`.
7. Facoltativamente esaminare in sola lettura `LabRole` e `LabInstanceProfile` con i comandi indicati. Questi oggetti sono preesistenti e non vanno modificati o eliminati.
8. Documentare metriche, snapshot/versioning, policy e decisioni simulate. Distinguere la simulazione di un documento JSON dalle autorizzazioni reali della sessione Academy: non eseguire un upload reale per dimostrare la policy simulata.
9. Conservare policy e risultati nel deliverable ed eseguire il cleanup delle sole risorse di esercitazione non più necessarie. Questa parte IAM non crea ruoli, policy gestite o instance profile su AWS.

Se l'API di simulazione viene negata da ulteriori limiti dell'account o il Learner Lab non è disponibile, consegnare il JSON e la tabella delle decisioni attese, indicando **simulazione non eseguita**. Non creare ruoli o cambiare credenziali per aggirare il limite.

### Policy JSON sul singolo bucket

Salvare come `lab12-s3-readonly.json` e sostituire `NOME_BUCKET_REALE` in entrambe le risorse:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::NOME_BUCKET_REALE"
    },
    {
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::NOME_BUCKET_REALE/*"
    }
  ]
}
```

`ListBucket` usa l'ARN del bucket; `GetObject` usa gli ARN degli oggetti (`/*`). Non serve una trust policy perché non viene creato né assunto un nuovo ruolo.

## Esempio di deliverable compilato

| # | Elemento | Evidenza sintetica |
| ---: | --- | --- |
| 1 | Analisi collo di bottiglia | Metriche e limiti confrontati; ipotesi motivata o dati insufficienti |
| 2 | Snapshot verificato | Volume dati, data e stato `completed` |
| 3 | Versioning verificato | Bucket del Lab 08, stato `Enabled` |
| 4 | Policy progettata | `ListBucket` sul bucket e `GetObject` sugli oggetti del solo bucket scelto |
| 5 | Simulazione | Lettura consentita, scrittura e lettura su altro bucket negate implicitamente |
| 6 | Risorse IAM | Nessuna creata o modificata; `LabRole` invariato |

## Comandi eseguiti e output

Verifica delle metriche CloudWatch per la diagnosi (CPU/rete vs storage). Sostituire gli ID e le date di esempio con l'intervallo reale del lab in UTC; un intervallo senza attività può restituire dati vuoti:

**Ubuntu (bash) / macOS (zsh/bash)**

```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 --metric-name NetworkIn \
  --dimensions Name=InstanceId,Value=<instance-id-demo-web-01> \
  --start-time 2026-07-21T00:00:00Z --end-time 2026-07-21T12:00:00Z \
  --period 3600 --statistics Average --query "Datapoints[].Average"

aws cloudwatch get-metric-statistics \
  --namespace AWS/EBS --metric-name VolumeReadOps \
  --dimensions Name=VolumeId,Value=<volume-id-demo-data-vol> \
  --start-time 2026-07-21T00:00:00Z --end-time 2026-07-21T12:00:00Z \
  --period 3600 --statistics Sum --query "Datapoints[].Sum"
```

**Windows PowerShell**

```powershell
aws cloudwatch get-metric-statistics `
  --namespace AWS/EC2 --metric-name NetworkIn `
  --dimensions Name=InstanceId,Value=<instance-id-demo-web-01> `
  --start-time 2026-07-21T00:00:00Z --end-time 2026-07-21T12:00:00Z `
  --period 3600 --statistics Average --query "Datapoints[].Average"

aws cloudwatch get-metric-statistics `
  --namespace AWS/EBS --metric-name VolumeReadOps `
  --dimensions Name=VolumeId,Value=<volume-id-demo-data-vol> `
  --start-time 2026-07-21T00:00:00Z --end-time 2026-07-21T12:00:00Z `
  --period 3600 --statistics Sum --query "Datapoints[].Sum"
```

Output atteso (illustrativo: i valori reali dipendono dal carico effettivo generato durante il lab):

```
[12.4, 15.1, 10.8]
[842.0, 910.0, 875.0]
```

Questi numeri illustrano il formato degli output, non dimostrano saturazione. Rapportare le operazioni al periodo (IOPS = operazioni / secondi), confrontarle con la capacità del volume e cercare una coda persistente prima di formulare una diagnosi.

### Simulare la policy senza creare un ruolo

Eseguire **sul computer locale**, nella cartella di `lab12-s3-readonly.json`, con credenziali temporanee complete di session token. I comandi su una riga sono validi in **Ubuntu/bash, macOS/zsh e Windows PowerShell**. Sostituire `NOME_BUCKET_REALE`; scegliere per l'ultima prova un nome diverso, che non deve necessariamente esistere perché la richiesta S3 è simulata.

```bash
aws sts get-caller-identity
aws iam simulate-custom-policy --policy-input-list file://lab12-s3-readonly.json --action-names s3:ListBucket --resource-arns arn:aws:s3:::NOME_BUCKET_REALE --query "EvaluationResults[].{Action:EvalActionName,Resource:EvalResourceName,Decision:EvalDecision}" --output table
aws iam simulate-custom-policy --policy-input-list file://lab12-s3-readonly.json --action-names s3:GetObject s3:PutObject --resource-arns arn:aws:s3:::NOME_BUCKET_REALE/report.txt --query "EvaluationResults[].{Action:EvalActionName,Resource:EvalResourceName,Decision:EvalDecision}" --output table
aws iam simulate-custom-policy --policy-input-list file://lab12-s3-readonly.json --action-names s3:GetObject --resource-arns arn:aws:s3:::lab12-altro-bucket-esempio/report.txt --query "EvaluationResults[].{Action:EvalActionName,Resource:EvalResourceName,Decision:EvalDecision}" --output table
```

Decisioni attese del **solo documento fornito**:

| Azione | Risorsa | Decisione |
| --- | --- | --- |
| `s3:ListBucket` | Bucket scelto | `allowed` |
| `s3:GetObject` | Oggetto del bucket scelto | `allowed` |
| `s3:PutObject` | Oggetto del bucket scelto | `implicitDeny` |
| `s3:GetObject` | Oggetto di un altro bucket | `implicitDeny` |

Il simulatore non invia queste richieste a S3 e non applica il JSON alla sessione o all'istanza. Non dimostra che un upload reale con `LabRole` sarebbe negato: il ruolo può avere altri Allow. Non sono stati qui inclusi tutti gli eventuali controlli dell'account, bucket policy, SCP o limiti di sessione. [Documentazione AWS sulla simulazione](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_testing-policies.html).

### Ispezione facoltativa in sola lettura

```bash
aws iam get-role --role-name LabRole --query "Role.{RoleName:RoleName,Arn:Arn,Trust:AssumeRolePolicyDocument}"
aws iam get-instance-profile --instance-profile-name LabInstanceProfile --query "InstanceProfile.{Name:InstanceProfileName,Roles:Roles[].RoleName}"
```

La trust policy mostra chi può assumere un ruolo; non è l'elenco delle operazioni consentite dal ruolo. La sola lettura di questi oggetti non determina tutti i permessi effettivi della sessione.

## Template operativo

```markdown
# Deliverable Lab 12

## Analisi collo di bottiglia
- ID istanza e volume: ...
- CPU/rete, IOPS, coda e intervallo osservato: ...
- Conclusione motivata o dati insufficienti: ...

## Verifica resilienza
- Snapshot recente: ID, data, stato ...
- Versioning del bucket: ...

## Policy e simulazione
- File: lab12-s3-readonly.json
- Bucket scelto: ...
- ListBucket/GetObject nel bucket: allowed / non eseguito
- PutObject nel bucket: implicitDeny / non eseguito
- GetObject in altro bucket: implicitDeny / non eseguito
- Questi risultati riguardano il documento simulato, non una prova S3 reale.
- Ruoli/policy gestite/instance profile creati o modificati: nessuno
- LabRole modificato: NO

## Cleanup
- Risorse dei lab precedenti ancora necessarie: ...
- Risorse di prova non più necessarie rimosse: ...
```

## Esempio sintetico

- Decisione corretta: progettare una policy minima e simularla senza richiedere la creazione di un ruolo non autorizzato.
- Evidenza minima: confronto rete/storage e tabella delle decisioni della simulazione.
- Fallback: JSON e decisioni attese documentate, con indicazione delle parti non eseguite.
- Cleanup atteso: nessuna nuova identità IAM da eliminare; rimuovere solo risorse di prova proprie non più necessarie.

## Checkpoint

- [x] Metriche CloudWatch confrontate esplicitamente
- [x] Snapshot e versioning verificati
- [x] Policy limitata a un bucket e agli oggetti necessari
- [x] Simulazione distinta da un test effettivo su S3
- [x] Nessuna creazione di ruoli o modifica di `LabRole`/`LabInstanceProfile`

## Errori comuni da evitare

- Interpretare `CreatePolicy` o `CreateInstanceProfile` come permesso di creare un ruolo.
- Tentare `CreateRole`, `AttachRolePolicy` o una policy inline su un ruolo applicativo arbitrario con le autorizzazioni fornite.
- Pensare che una policy di sola lettura aggiunta a un ruolo elimini gli Allow più ampi già presenti: gli Allow si combinano.
- Confondere `implicitDeny` della simulazione con l'esito garantito di una chiamata reale della sessione Academy.
- Modificare o eliminare ruoli e risorse preesistenti dell'Academy durante il cleanup.

## Troubleshooting rapido

- `ExpiredToken`: aggiornare tutte le credenziali temporanee, incluso il session token.
- Errore di lettura del JSON: controllare directory corrente, nome del file e sintassi JSON.
- Lettura simulata negata: verificare nome del bucket e distinzione fra ARN bucket e ARN oggetto.
- `AccessDenied` sul simulatore: documentare il limite aggiuntivo e usare il fallback; non creare un ruolo per risolverlo.
- Metriche mancanti: verificare ID, regione, namespace e intervallo temporale effettivo.

## Cleanup obbligatorio

- Conservare il JSON e gli esiti come evidenza didattica; non contengono credenziali.
- Non eliminare o modificare `LabRole`, `LabInstanceProfile` o i componenti di sistema e monitoring Academy.
- Fermare le istanze e rimuovere solo le risorse di test proprie non più necessarie, seguendo i cleanup dei Lab 07/08; documentare quelle conservate per i lab successivi.
- Non dichiarare eliminati ruoli o policy di test: questa procedura non ne ha creati.
