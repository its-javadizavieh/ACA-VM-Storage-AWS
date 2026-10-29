# Lab 09 - Storage Gateway e Crittografia dei Dati

## Obiettivo

- Focus operativo: creare un volume EBS cifrato e abilitare la cifratura di default su un bucket S3, e motivare la scelta di una tipologia di Storage Gateway per uno scenario ibrido assegnato.
- Deliverable atteso: volume EBS cifrato verificato in console, bucket con cifratura di default e oggetto cifrato, tabella di motivazione sulla tipologia di Storage Gateway.
- Nomi di risorsa usati in questa soluzione: volume `demo-encrypted-vol`, bucket riusato dal Lab 08 (`demo-vm-reti-storage-<iniziali>-2026`).

## Prerequisiti

- Accesso attivo all'AWS Academy Learner Lab.
- AWS Management Console o AWS CLI configurata con le credenziali del Learner Lab.
- Conoscenza base di volumi EBS e bucket S3 (dai lab precedenti).
- Fallback previsto: se il Learner Lab non è raggiungibile, documentare lo scenario di Storage Gateway e la strategia di cifratura pianificata su tabella Markdown, senza creare risorse reali.

## Scenario

- Il tuo gruppo deve dimostrare come proteggere dati sensibili del progetto sia a riposo che in transito, e descrivere come un ambiente ibrido potrebbe integrare storage locale e cloud.
- Devi creare un volume EBS cifrato per un nuovo servizio dati e abilitare la cifratura di default su un bucket S3 per documenti sensibili.
- Devi scegliere e motivare, in forma di documento (senza necessariamente distribuire l'appliance reale, spesso non disponibile nel Learner Lab), quale tipologia di Storage Gateway sarebbe adatta a un ipotetico scenario ibrido assegnato dal docente.

## Step

1. Aprire **Storage Gateway → Create gateway** solo per esaminare i tipi, senza completare la distribuzione: **S3 File Gateway** per NFS/SMB, **Volume Gateway** per iSCSI, **Tape Gateway** per nastri virtuali. Annotare quale interfaccia serve allo scenario; se la console non è accessibile usare la tabella documentale.
2. Motivare la scelta con un esempio: per mantenere un'applicazione di backup che usa nastri virtuali, scegliere Tape Gateway. Chiudere il wizard senza creare un gateway.
3. In **EC2 → Volumes → Create volume**, impostare `gp3`, 10 GiB, AZ dell'istanza di destinazione, tag `Name = demo-encrypted-vol`, **Encryption → Encrypt this volume**, chiave `aws/ebs`. Creare il volume, attendere `available` e verificare **Encrypted = Yes** e la chiave indicata nei dettagli.
4. Riusare il bucket del Lab 08 oppure crearne uno con nome univoco, nella regione del lab e con **Block all public access** attivo.
5. Aprire **Properties → Default encryption → Edit**, verificare/selezionare **Server-side encryption with Amazon S3 managed keys (SSE-S3)** e salvare. Se è già attiva, documentarla senza cambiarla.
6. Preparare `test-cifratura.txt`, caricarlo con **Upload → Add files → Upload**, poi aprire l'oggetto → **Properties → Server-side encryption settings**. Confermare SSE-S3/AES256 anche con `head-object`.
7. Documentare la chiave KMS del volume e l'algoritmo SSE-S3 dell'oggetto. Distinguere cifratura a riposo da HTTPS, usato per il trasferimento: la verifica dell'una non prova automaticamente l'altra.
8. Eliminare il volume cifrato se non serve più e le versioni del solo oggetto di prova. Conservare il bucket condiviso se richiesto dal Lab 12; altrimenti svuotarlo completamente ed eliminarlo.

## Esempio di deliverable compilato

|    # | Elemento                  | Evidenza sintetica                                                         |
| ---: | ------------------------- | -------------------------------------------------------------------------- |
|    1 | Volume EBS cifrato        | `demo-encrypted-vol`, `gp3`, 10 GiB, Encrypted = `Yes`, chiave `aws/ebs`   |
|    2 | Bucket con cifratura      | `demo-vm-reti-storage-<iniziali>-2026`, Default encryption = SSE-S3        |
|    3 | Oggetto cifrato           | file di test con "Server-side encryption settings" = AES-256 (SSE-S3)      |
|    4 | Tipologia Storage Gateway | scelta motivata in base all'interfaccia richiesta dallo scenario assegnato |

## Comandi eseguiti e output

Verifica della cifratura del volume EBS:

**Ubuntu (bash) / macOS (zsh/bash)**

```bash
aws ec2 describe-volumes \
  --filters "Name=tag:Name,Values=demo-encrypted-vol" \
  --query "Volumes[].{Encrypted:Encrypted,KmsKeyId:KmsKeyId,State:State}"
```

**Windows PowerShell**

```powershell
aws ec2 describe-volumes `
  --filters "Name=tag:Name,Values=demo-encrypted-vol" `
  --query "Volumes[].{Encrypted:Encrypted,KmsKeyId:KmsKeyId,State:State}"
```

Output atteso (illustrativo: l'ARN della chiave KMS gestita da AWS varia per account/regione):

```
[
    {"Encrypted": true, "KmsKeyId": "arn:aws:kms:us-east-1:123456789012:key/aws/ebs", "State": "available"}
]
```

Verifica della cifratura di default sul bucket:

**Ubuntu (bash) / macOS (zsh/bash) / Windows PowerShell**

```powershell
aws s3api get-bucket-encryption --bucket demo-vm-reti-storage-<iniziali>-2026
```

Output atteso:

```
{
    "ServerSideEncryptionConfiguration": {
        "Rules": [
            {"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}
        ]
    }
}
```

Verifica della cifratura dell'oggetto caricato:

**Ubuntu (bash) / macOS (zsh/bash)**

```bash
aws s3api head-object --bucket demo-vm-reti-storage-<iniziali>-2026 --key test-cifratura.txt \
  --query "ServerSideEncryption"
```

**Windows PowerShell**

```powershell
aws s3api head-object --bucket demo-vm-reti-storage-<iniziali>-2026 --key test-cifratura.txt `
  --query "ServerSideEncryption"
```

Output atteso:

```
"AES256"
```

Il campo `Encrypted: true` sul volume e `ServerSideEncryption: AES256` sull'oggetto confermano che la cifratura a riposo è effettivamente applicata, non solo configurata.

## Template operativo

```markdown
# Deliverable Lab 09

## Volume EBS cifrato
- Nome: demo-encrypted-vol
- Tipo/Dimensione: gp3, 10 GiB
- Encrypted: Yes
- Chiave: aws/ebs (gestita da AWS)

## Bucket con cifratura di default
- Nome: demo-vm-reti-storage-<iniziali>-2026
- Algoritmo: SSE-S3 (AES256)
- Oggetto di test verificato cifrato: si

## Scelta Storage Gateway
| Tipologia | Interfaccia esposta | Caso d'uso adatto allo scenario |
| File Gateway | NFS/SMB | ... |
| Volume Gateway | iSCSI | ... |
| Tape Gateway | nastro virtuale | ... |
- Scelta motivata: ...

## Cleanup
- Volume cifrato eliminato: si/no
- Bucket svuotato/eliminato (se non riusato per altri lab): si/no
```

## Esempio sintetico

- Decisione corretta: verificare esplicitamente il campo `Encrypted`/`ServerSideEncryption` in console o via CLI, non assumere che la cifratura sia attiva solo perché l'opzione era selezionata nel wizard.
- Evidenza minima: stato di cifratura confermato sia sul volume sia sull'oggetto S3, più la tabella di motivazione sulla tipologia di Storage Gateway.
- Fallback accettabile: se il Learner Lab non è raggiungibile, documentare lo scenario di Storage Gateway e la strategia di cifratura su tabella Markdown.
- Cleanup atteso: volume cifrato eliminato; bucket svuotato ed eliminato solo se non riusato da un lab successivo (qui il bucket del Lab 08 può restare se il corso prosegue).

## Checkpoint

- [x] Volume EBS effettivamente cifrato, verificato dal campo Encryption
- [x] Bucket S3 con cifratura di default attiva a livello di bucket, non solo di singolo oggetto
- [x] Scelta della tipologia di Storage Gateway motivata rispetto all'interfaccia richiesta dallo scenario
- [x] Cleanup eseguito o giustificato

## Errori comuni da evitare

- Creare il volume senza abilitare esplicitamente l'opzione di cifratura, assumendo che sia attiva di default.
- Configurare la cifratura solo al momento dell'upload di un singolo oggetto, invece che come default a livello di bucket.
- Scegliere la tipologia di Storage Gateway senza collegarla all'interfaccia realmente richiesta dallo scenario (file, blocco o nastro).
- Tentare di "convertire" un volume non cifrato in cifrato senza passare da uno snapshot e un nuovo volume.

## Troubleshooting rapido

- Se la creazione del volume cifrato fallisce, verifica di aver usato una chiave KMS valida e accessibile nella regione del Learner Lab (o la chiave gestita da AWS di default).
- Se un volume EBS esistente non cifrato deve diventare cifrato, ricorda che serve creare uno snapshot e un nuovo volume cifrato da esso: non esiste conversione diretta "sul posto".
- Se la cifratura di default del bucket non sembra applicarsi, verifica di aver salvato correttamente la configurazione a livello di bucket, non solo a livello di singolo oggetto.
- Se non è chiaro quale tipologia di Storage Gateway scegliere, ripassa la differenza tra interfaccia file (NFS/SMB), blocco (iSCSI) e nastro virtuale prima di rispondere.

## Cleanup obbligatorio

- Elimina il volume EBS cifrato creato per il test.
- Se il bucket serve al Lab 12, conserva bucket e oggetto di lettura, rimuovendo solo il file di prova non necessario. Altrimenti svuota tutte le versioni e i delete marker ed elimina il bucket.
- Verifica che non restino oggetti o volumi di test residui nell'account del Learner Lab.
- Conferma nel deliverable che il cleanup è stato completato o indica cosa non è stato possibile rimuovere.
