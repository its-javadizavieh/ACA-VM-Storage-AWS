# Lab 14 - Backup, Disaster Recovery e Ottimizzazione dei Costi

## Obiettivo

- Focus operativo: definire RPO/RTO e strategia di DR per un progetto didattico, creare un backup plan minimo con AWS Backup, e analizzare i costi del corso con Cost Explorer proponendo un'ottimizzazione.
- Deliverable atteso: tabella RPO/RTO con strategia scelta, backup plan funzionante con risorsa assegnata, analisi costi con azione di ottimizzazione motivata.
- Nomi di risorsa usati in questa soluzione: backup vault `demo-backup-vault`, backup plan `demo-backup-plan`, regola `demo-daily-rule`.

## Prerequisiti

- Accesso attivo all'AWS Academy Learner Lab, con un volume EBS o altra risorsa critica dai lab precedenti.
- AWS Management Console o AWS CLI configurata con le credenziali del Learner Lab.
- Accesso a Cost Explorer (potrebbe richiedere abilitazione o avere dati limitati in un Learner Lab con budget di crediti ridotto).
- Usare la stessa regione per il volume e per AWS Backup: `us-east-1` oppure `us-west-2`. Per l'assegnazione delle risorse usare `LabRole`, già predisposto dall'Academy.
- Fallback previsto: se il Learner Lab non è raggiungibile o Cost Explorer non mostra dati sufficienti, documentare RPO/RTO, strategia di DR e ipotesi di ottimizzazione su tabella Markdown.

## Scenario

- Il tuo gruppo deve proporre una strategia di backup/Disaster Recovery proporzionata a un progetto didattico, e un'analisi dei costi delle risorse usate finora nel corso.
- Devi definire RPO e RTO accettabili per il progetto, scegliere la strategia di DR più adatta e creare un backup plan minimo per una risorsa critica.
- Devi analizzare Cost Explorer (o simulare l'analisi via fallback) per identificare la risorsa più costosa e proporre un'azione di ottimizzazione concreta.

## Step

1. Definire RPO `24 ore`, RTO `poche ore` e strategia **Backup and Restore** per lo scenario didattico. Indicare che sono obiettivi progettuali: la creazione del piano non dimostra da sola il tempo di ripristino.
2. Verificare che il volume `demo-data-vol` esista e annotarne ID e regione; se eliminato, creare un volume dati di test seguendo il Lab 07.
3. Aprire **AWS Backup → Backup vaults → Create backup vault**, nome `demo-backup-vault`, chiave di cifratura consentita nel lab; creare il vault.
4. In **Backup plans → Create backup plan**, scegliere un piano nuovo, nome `demo-backup-plan`; aggiungere regola `demo-daily-rule`, destinazione `demo-backup-vault`, frequenza **Daily**, retention **7 giorni**. Annotare orario, fuso e finestra di backup; creare il piano.
5. Nella pagina del piano scegliere **Assign resources**, nome `demo-assignment-ebs`, quindi **IAM role → Choose an IAM role → LabRole**, usando il ruolo Academy già esistente. Non scegliere la creazione del ruolo predefinito `AWSBackupDefaultServiceRole`: il percorso di questo lab usa soltanto il ruolo preesistente. In **Resource selection → Include specific resource types**, selezionare **EBS** e il Volume ID reale, poi **Assign resources**. Se `LabRole` non è selezionabile o l'assegnazione è negata, documentare il limite e usare il fallback senza creare o modificare ruoli.
6. Verificare in **Resource assignments** l'assegnazione e in **Backup jobs** eventuali esecuzioni. Il primo job segue la finestra configurata: se non è ancora avvenuto, documentare solo il piano/assegnazione, senza dichiarare un backup completato.
7. Aprire **Cost Explorer**, impostare **Date range → ultimi 7 giorni**, **Granularity → Daily**, **Group by → Service**. Le policy includono `ce:*`, ma ciò non garantisce che i dati di fatturazione siano accessibili o che Cost Explorer sia attivo nell'account Academy: se non disponibile o senza dati, usare il fallback e indicare che le cifre sono ipotesi. Usare filtri per tag solo se quei tag di allocazione dei costi sono già attivati; non richiedere allo studente modifiche alla fatturazione dell'account.
8. Individuare il servizio più costoso nella tabella del periodo. Confrontare la spesa con **EC2 → Instances**, **Volumes**, **Snapshots** e **VPC → NAT Gateways** per cercare risorse lasciate attive o non utilizzate; il solo totale per servizio non prova quale risorsa abbia causato la spesa.
9. Proporre un'azione concreta e motivata (fermare istanze non usate, eliminare volumi/snapshot di test inutili, rimuovere NAT Gateway non necessario). Documentare dati e ipotesi, poi eseguire il cleanup nell'ordine indicato sotto.

## Esempio di deliverable compilato

|    # | Elemento                             | Evidenza sintetica                                                 |
| ---: | ------------------------------------ | ------------------------------------------------------------------ |
|    1 | RPO/RTO                              | RPO 24h, RTO poche ore, strategia Backup and Restore               |
|    2 | Backup vault/plan                    | `demo-backup-vault`, `demo-backup-plan` (regola `demo-daily-rule`) |
|    3 | Risorsa assegnata                    | volume `demo-data-vol`                                             |
|    4 | Servizio più costoso (Cost Explorer) | EC2 (istanze rimaste attive tra un lab e l'altro)                  |
|    5 | Azione di ottimizzazione             | fermare le istanze non in uso attivo tra una sessione e l'altra    |

## Comandi eseguiti e output

Verifica in sola lettura del ruolo preesistente, prima dell'assegnazione (comando valido anche in PowerShell):

```bash
aws iam get-role --role-name LabRole --query "Role.{Arn:Arn,Trust:AssumeRolePolicyDocument}"
```

Controllare la presenza di `backup.amazonaws.com` fra i servizi trusted. Il ruolo deve anche mantenere i permessi per il backup EBS; la sola presenza nella lista non prova che un job sia riuscito. Nessun comando di questo lab crea o modifica un ruolo. La creazione automatica del ruolo di default richiede autorizzazioni IAM ulteriori ([ruoli di servizio AWS Backup](https://docs.aws.amazon.com/aws-backup/latest/devguide/iam-service-roles.html)).

Verifica della configurazione del backup plan e dell'assegnazione:

**Ubuntu (bash) / macOS (zsh/bash)**

```bash
aws backup list-backup-plans --query "BackupPlansList[?BackupPlanName=='demo-backup-plan']"

aws backup list-backup-selections --backup-plan-id <plan-id-demo-backup-plan> \
  --query "BackupSelectionsList[].SelectionName"
```

**Windows PowerShell**

```powershell
aws backup list-backup-plans --query "BackupPlansList[?BackupPlanName=='demo-backup-plan']"

aws backup list-backup-selections --backup-plan-id <plan-id-demo-backup-plan> `
  --query "BackupSelectionsList[].SelectionName"
```

Output atteso (illustrativo: l'ID del piano varia a ogni creazione reale):

```
[{"BackupPlanId": "abc-123-demo", "BackupPlanName": "demo-backup-plan"}]
["demo-assignment-ebs"]
```

Analisi dei costi per servizio tramite Cost Explorer (AWS CLI). Sostituire le date con il periodo reale, ricordando che `End` è esclusivo; il comando seguente mostra l'ultimo giorno restituito, mentre la console permette di confrontare il totale dell'intero periodo:

**Ubuntu (bash) / macOS (zsh/bash)**

```bash
aws ce get-cost-and-usage \
  --region us-east-1 \
  --time-period Start=2026-07-15,End=2026-07-21 \
  --granularity DAILY --metrics "UnblendedCost" \
  --group-by Type=DIMENSION,Key=SERVICE \
  --query "ResultsByTime[-1].Groups[].{Service:Keys[0],Cost:Metrics.UnblendedCost.Amount}"
```

**Windows PowerShell**

```powershell
aws ce get-cost-and-usage `
  --region us-east-1 `
  --time-period Start=2026-07-15,End=2026-07-21 `
  --granularity DAILY --metrics "UnblendedCost" `
  --group-by Type=DIMENSION,Key=SERVICE `
  --query "ResultsByTime[-1].Groups[].{Service:Keys[0],Cost:Metrics.UnblendedCost.Amount}"
```

Output atteso (illustrativo: i valori reali dipendono dalle risorse effettivamente usate nel corso):

```
[
    {"Service": "Amazon Elastic Compute Cloud - Compute", "Cost": "1.42"},
    {"Service": "Amazon Elastic Block Store", "Cost": "0.08"},
    {"Service": "Amazon Simple Storage Service", "Cost": "0.01"}
]
```

Una spesa EC2 prevalente suggerisce di controllare le istanze e i loro tempi di utilizzo; questi valori illustrativi, da soli, non dimostrano che siano state lasciate attive inutilmente.

## Template operativo

```markdown
# Deliverable Lab 14

## RPO/RTO e strategia DR
- RPO: 24 ore
- RTO: poche ore
- Strategia: Backup and Restore

## Backup plan
- Vault: demo-backup-vault
- Plan: demo-backup-plan (regola demo-daily-rule, retention 7 giorni)
- Risorsa assegnata: demo-data-vol
- Ruolo preesistente scelto: LabRole (nessun nuovo ruolo creato)

## Analisi costi
- Servizio più costoso: EC2
- Ipotesi causa: istanze rimaste attive tra le sessioni di lab
- Azione di ottimizzazione proposta: fermare le istanze a fine sessione, non solo a fine corso

## Cleanup
- Backup plan e selection eliminati: si/no
- Backup vault eliminato: si/no
```

## Esempio sintetico

- Decisione corretta: scegliere Backup and Restore (non Pilot Light o Warm Standby) per un progetto didattico a basso traffico, dove un RTO più alto è accettabile in cambio di un costo minimo.
- Evidenza minima: l'assegnazione della risorsa al backup plan verificata concretamente, più un dato reale (o un'ipotesi motivata via fallback) da Cost Explorer.
- Fallback accettabile: se Cost Explorer non mostra dati sufficienti (budget di crediti limitato), documentare RPO/RTO e ipotesi di ottimizzazione su tabella Markdown basandosi sui tipi di risorse create nei lab precedenti.
- Cleanup atteso: backup plan, selection e vault eliminati, senza aver mai eliminato la risorsa critica reale per errore.

## Checkpoint

- [x] RPO e RTO definiti con valori concreti, coerenti con un progetto didattico a basso traffico
- [x] Backup plan include una risorsa critica reale del corso, non una risorsa generica
- [x] Azione di ottimizzazione basata su un dato osservato (o un'ipotesi motivata via fallback), non generica
- [x] Cleanup (backup plan, selection, vault) eseguito o giustificato

## Errori comuni da evitare

- Scegliere **Default role** e aspettarsi che il Learner Lab possa creare e passare `AWSBackupDefaultServiceRole`: usare invece `LabRole` già predisposto, senza modificarlo.
- Scegliere una strategia di DR sproporzionata (es. Multi-site attivo-attivo) per un progetto didattico a basso traffico.
- Assegnare al backup plan una risorsa generica non collegata al progetto, invece di una risorsa critica reale del corso.
- Proporre un'azione di ottimizzazione generica ("ridurre i costi") senza collegarla a un dato specifico osservato in Cost Explorer.
- Eliminare per errore la risorsa critica reale durante il test del backup, invece delle sole risorse di test create per l'esercitazione.

## Troubleshooting rapido

- Se AWS Backup non mostra risorse disponibili da selezionare, verifica di aver taggato correttamente la risorsa o di aver selezionato il tipo di risorsa corretto nel backup plan.
- Se Cost Explorer non mostra dati recenti, ricorda che l'aggiornamento dei costi può avere un ritardo di alcune ore rispetto all'uso effettivo delle risorse.
- Se il Learner Lab ha crediti troppo limitati per popolare dati significativi in Cost Explorer, usa il fallback documentale basandoti sui tipi di risorse create nei lab precedenti.
- Se il backup job non parte nei tempi del lab, documenta comunque la configurazione del piano come evidenza, annotando che l'esecuzione effettiva richiede più tempo.

## Cleanup obbligatorio

- In **Backup plans → demo-backup-plan → Resource assignments**, elimina prima `demo-assignment-ebs`, poi elimina il piano.
- In **Backup vaults → demo-backup-vault → Backups**, elimina gli eventuali recovery point di test non più necessari; quando il vault è vuoto, eliminalo. Non eliminare il volume sorgente per rimuovere il backup.
- Verifica che nessuna risorsa critica reale sia stata eliminata per errore durante il test del backup.
- Non eliminare `LabRole`, policy Academy o il ruolo di servizio di altri ambienti durante il cleanup.
- Conferma nel deliverable che il cleanup è stato completato o indica cosa non è stato possibile rimuovere.
